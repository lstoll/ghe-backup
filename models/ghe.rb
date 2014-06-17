# encoding: utf-8
require 'fileutils'

##
# Backup Generated: ghe
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t ghe [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://meskyanichi.github.io/backup
#
Model.new(:ghe, 'Description for ghe') do

  STAGING_PATH  = ENV['STAGING_PATH'] || File.join(Dir.tmpdir, 'ghe-stage')
  S3_REGION     = ENV['S3_REGION'] || 'us-east-1'
  S3_ACCESS_KEY = ENV['S3_ACCESS_KEY'] || raise("S3_ACCESS_KEY required")
  S3_SECRET_KEY = ENV['S3_SECRET_KEY'] || raise("S3_SECRET_KEY required")
  S3_BUCKET     = ENV['S3_BUCKET'] || raise("S3_BUCKET required")
  S3_PATH       = ENV['S3_PATH']


  # Prep the backup - we need to get exports of all the data
  before do
    FileUtils.mkdir_p(STAGING_PATH)

    export_commands = [
      'ghe-export-repositories > ghe-repositories-backup.tar',
      'ghe-export-pages > ghe-pages-backup.tar',
      'ghe-export-mysql | gzip > ghe-mysql-backup.sql.gz',
      'ghe-export-redis > ghe-redis-backup.rdb',
      'ghe-export-authorized-keys > ghe-authorized-keys-backup.json',
      'ghe-export-ssh-host-keys > ghe-ssh-host-keys-backup.tar',
      'ghe-export-es-indices > ghe-es-indices-backup.tar',
      'ghe-export-settings > settings.json'
    ]

    Dir.chdir(STAGING_PATH) do |stage_dir|
      export_commands.each do |export_command|
        unless system(export_command)
          raise RuntimeError.new("Command #{export_command} failed to execute")
        end
      end
    end
  end

  # Clean up the temp staging stuff
  after do
    FileUtils.rm_r(STAGING_PATH)
  end

  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  split_into_chunks_of 250
  ##
  # Archive [Archive]
  #
  # Adding a file or directory (including sub-directories):
  #   archive.add "/path/to/a/file.rb"
  #   archive.add "/path/to/a/directory/"
  #
  # Excluding a file or directory (including sub-directories):
  #   archive.exclude "/path/to/an/excluded_file.rb"
  #   archive.exclude "/path/to/an/excluded_directory
  #
  # By default, relative paths will be relative to the directory
  # where `backup perform` is executed, and they will be expanded
  # to the root of the filesystem when added to the archive.
  #
  # If a `root` path is set, relative paths will be relative to the
  # given `root` path and will not be expanded when added to the archive.
  #
  #   archive.root '/path/to/archive/root'
  #
  archive :my_archive do |archive|
    # Run the `tar` command using `sudo`
    # archive.use_sudo
    archive.add STAGING_PATH
  end

  ##
  # Amazon Simple Storage Service [Storage]
  #
  store_with S3 do |s3|
    # AWS Credentials
    s3.access_key_id     = S3_ACCESS_KEY
    s3.secret_access_key = S3_SECRET_KEY
    # Or, to use a IAM Profile:
    # s3.use_iam_profile = true

    s3.region            = S3_REGION
    s3.bucket            = S3_BACKUP
    s3.path              = S3_PATH
  end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the documentation for other delivery options.
  #
  # notify_by Mail do |mail|
  #   mail.on_success           = true
  #   mail.on_warning           = true
  #   mail.on_failure           = true
  #
  #   mail.from                 = "sender@email.com"
  #   mail.to                   = "receiver@email.com"
  #   mail.address              = "smtp.gmail.com"
  #   mail.port                 = 587
  #   mail.domain               = "your.host.name"
  #   mail.user_name            = "sender@email.com"
  #   mail.password             = "my_password"
  #   mail.authentication       = "plain"
  #   mail.encryption           = :starttls
  # end

end
