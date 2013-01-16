# Installation

## 1. Clone
    git clone https://github.com/lieldulev/perseus-shield.git

## 2. Bundle
    bundle install

## 3. Configure
Open `config/perseus-shield.yml` and make sure to update all the fields:

    # redis server host:port
    redis: localhost:6379

    # all cache keys will be prefixed with this
    cache_key_prefix: persues_shield

    # the bucket name to store the files in
    s3_bucket: my.bucket.s3
    # the root to use in the bucket, can be left empty
    s3_root:

    # AWS credentials
    aws_key: YOUR_KEY
    aws_secret: YOUR_SECRET

    # only urls that match this regex will be resized (no need for / at the start/end)
    url_regex: ^https?:\/\/.*\.?mywebsite\.com\/.+$

    # schemaless uri that points to the bucket's root 
    external_uri: cloudfront.mywebsite.com

## 4. Run
     rails s

or add unicorn or whatever to the Gemfile and use that.

## 5. Resize
Replace

    <img src="http://domain.com/v/2F8217151_720_540.jpg" width="200px" />

With

    <img src="http://your-persues-server.com/r/?url=http%3A%2F%2Fdomain.com%2Fv1%2F8217151_720_540.jpg&width=200" />
