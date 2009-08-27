# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_pictr_session',
  :secret      => 'a0b397ae61e407bc4c8c75097e31c1e66ccf19ce1f59a5a7903508568ee0ca459d7aaeb70d8e2a19ab844f3a93c493d8d32da332e169dafee7916545a901ad42'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
