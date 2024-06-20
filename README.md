# BunnyStorage Client

BunnyStorage Client is a Ruby SDK for interacting with BunnyCDN storage services.

API Documentation: https://docs.bunny.net/reference/storage-api

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bunny_storage_client'
```

And then execute:

```bash
bundle install
```
Or install it yourself as:

```bash
gem install bunny_storage_client
```

## Usage

```ruby
# Initialize the client
client = BunnyStorageClient.new('your_access_key', 'your_api_key', 'your_storage_zone')

# Set the object
client.object('your_filename')

# Upload a file
client.upload_file(body: File.open('path/to/local/file'))

# Retrieve a file as a string
file_content = client.get_file(as: :string)

# Retrieve a file as a tempfile
file_temp = client.get_file(as: :file)

# Delete a file
client.delete_file

# Purge cache
client.purge_cache
```

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/rkwap/bunny_storage_client.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


