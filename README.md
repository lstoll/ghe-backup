# ghe-backup

Utility for backing up a GitHub Enterprise system. Powered by [backup](https://github.com/meskyanichi/backup) gem.

Designed to run on the instance itself, as the admin user. Probably via cron. Target is S3. Can send emails on failure via the system's mail config.

# configuring

Uses environment variables. You can set this in a [.env file](https://github.com/bkeepers/dotenv#usage) in the root of this project if you like.

Required variables:

* `S3_ACCESS_KEY`
* `S3_SECRET_KEY`
* `S3_BUCKET`

Optional variables:

* `NOTIFICATION_EMAIL` - e-mail address to notify on failure
