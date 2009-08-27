require 'right_aws'
require 'sdb/active_sdb'
RightAws::ActiveSdb.establish_connection


class AlreadyExistsError < RuntimeError; end

class Picture < RightAws::ActiveSdb::Base
  UPLOAD_BUCKET="pictr"
  
  def remove_stored_images
    s3 = RightAws::S3.new
    bucket = s3.bucket(UPLOAD_BUCKET)
    self["total_conversions"].each do |t|
      bucket.key(self[t][0]).delete
    end
  end
  
  def done_processing?
    self.reload
    self["total_conversions"] && self["total_conversions"].all? {|c| self[c]}
  end
  
  # Helper method
  def process_missing_images
    self.reload
    self.remove_stored_images
    jobs = queue_jobs
    self["total_conversions"] = jobs.map(&:suffix)
    self.save
    # TODO remove stale images from s3
  end
        
  
  def self.create_with_jobs(key)
    raise AlreadyExistsError if Picture.find_by_key(key)
    
    picture = self.create(:key => key, :updated_at => Time.now.gmtime.iso8601)  
    jobs = picture.queue_jobs
    
    # Create the SDB database entry for this picture
    picture["total_conversions"] = jobs.map(&:suffix)
    picture.save
    
    return picture
  end
  
  def queue_jobs
    # Create the ConvertJobs that will take care of the actual processing
    key = self["key"][0]
    
    jobs = [
      #ConvertJob.new(key, "thumbnail", "100x100"), 
      #ConvertJob.new(key, "medium", "200"), 
      #ConvertJob.new(key, "original", "400"),
      ConvertJob.new(key, "paint", "400", "-paint 5"),
      ConvertJob.new(key, "monochrome", "400", "-monochrome")  
    ]
    
    # Put the jobs into thr SQS queue
    sqs = RightAws::SqsGen2.new
    convert_queue = sqs.queue("convert")
    
    jobs.each do |job|
      convert_queue.send_message job.to_json
    end
    return jobs
  end
  
  def processed_cloud_front_urls
    self["total_conversions"].map do |t|      
      "http://dhxkhmleiuoul.cloudfront.net/#{self[t]}"
    end    
  end
  
  def processed_s3_urls
    # TODO - hacky way to generate a url
    s3 = RightAws::S3.new
    bucket = s3.bucket(UPLOAD_BUCKET)  
    t = []
    
    self["total_conversions"].map do |t|      
      RightAws::S3::Key.new(bucket, self[t][0]).public_link
    end
  end
  
  def self.queue_size
    sqs = RightAws::SqsGen2.new
    convert_queue = sqs.queue("convert")
    return convert_queue.size
  end
  
  def self.db_size
    Picture.find(:all).size
  end
  
  def self.s3_size
    s3 = RightAws::S3.new
    bucket = s3.bucket(UPLOAD_BUCKET)
    return bucket.keys.size
  end

end
