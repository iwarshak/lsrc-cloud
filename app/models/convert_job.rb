require 'picture'

class ConvertJob
  attr_accessor :size, :options, :key, :suffix
  
  def initialize(key, suffix, size, options = nil)
    @key = key.to_s
    @suffix = suffix.to_s
    @size = size.to_s
    @options = options.to_s
  end
  
  def run!
    base_dir = FileUtils.mkdir_p(File.join(RAILS_ROOT, "tmp", "photo_processing"))
    basename = @key.split(/\//)[-1]
    original_file = File.join(base_dir, basename)
    new_file_basename = "#{basename}_#{@suffix}.jpg"
    new_file = File.join(base_dir, new_file_basename)
    
    s3 = RightAws::S3.new
    bucket = s3.bucket(Picture::UPLOAD_BUCKET)
    # download the original from s3 if we haven't done so already
    unless File.exists? original_file
      s3_object = bucket.key @key
      File.open(original_file, "w") {|f| f.write(s3_object.data)}
    end
    
    # convert veggies.jpg -resize 400 -charcoal 3 veggies_10.jpg
    # convert veggies.jpg -resize 400 -paint 5 veggies_10.jpg
    # convert veggies.jpg -resize 400 -polaroid 3 veggies_10.jpg
    # convert veggies.jpg -resize 400 -posterize 2 veggies_10.jpg
    # convert veggies.jpg -resize 400 -posterize 2 veggies_10.jpg
    # convert foo.jpg -font /home/rails/lsrc-cloud/current/files/Georgia.ttf -pointsize 30 -background Khaki  label:"`hostname`" -gravity Center -append  foo_label.jpg
    system("convert #{original_file} #{@options} -font #{RAILS_ROOT}/files/Georgia.ttf -pointsize 30 -background Khaki label:\"#{public_hostname}\" -gravity Center -append -resize #{@size}  #{new_file}")
    
    # upload to s3 with public-read
    processed_key = RightAws::S3::Key.create(bucket, "processed/#{new_file_basename}")
    processed_key.put(File.open(new_file).read, 'public-read')
    
    # update the database
    picture = Picture.select_by_key @key
    picture[suffix] = "processed/#{new_file_basename}"
    picture["updated_at"] = Time.now.gmtime.iso8601
    picture.save
    
    # remove the processed file since it is now in s3
    FileUtils.rm new_file
    return RightAws::S3::Key.new(bucket, "processed/#{new_file_basename}").public_link
  end
  
  
  
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'size'         => @size,
      'key'          => @key,
      'suffix'       => @suffix,
      'options'      => @options
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['key'], o['suffix'], o['size'], o['options'])
  end
  
private
  def public_hostname
    File.open("#{RAILS_ROOT}/files/server.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/server.txt")
  end
  

end