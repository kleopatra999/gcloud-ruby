# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "storage_helper"

describe Gcloud::Storage::Bucket, :storage do
  let(:bucket_name) { $bucket_names.first }
  let :bucket do
    storage.bucket(bucket_name) ||
    storage.create_bucket(bucket_name)
  end

  before do
    # always reset the bucket permissions
    bucket.acl.private!
  end

  it "creates and gets and updates and deletes a bucket" do
    one_off_bucket_name = "#{bucket_name}_one_off"

    storage.bucket(one_off_bucket_name).must_be :nil?

    one_off_bucket = storage.create_bucket(one_off_bucket_name)

    storage.bucket(one_off_bucket_name).wont_be :nil?

    one_off_bucket.website_main.must_be :nil?
    one_off_bucket.website_404.must_be :nil?
    one_off_bucket.update do |b|
      b.website_main = "index.html"
      b.website_404 = "not_found.html"
    end
    one_off_bucket.website_main.must_equal "index.html"
    one_off_bucket.website_404.must_equal "not_found.html"

    one_off_bucket_copy = storage.bucket one_off_bucket_name
    one_off_bucket_copy.wont_be :nil?
    one_off_bucket_copy.website_main.must_equal "index.html"
    one_off_bucket_copy.website_404.must_equal "not_found.html"

    one_off_bucket.files.all &:delete
    one_off_bucket.delete

    storage.bucket(one_off_bucket_name).must_be :nil?
  end

  it "knows its attributes" do
    bucket.id.must_be_kind_of String
    bucket.name.must_equal bucket_name
    bucket.created_at.must_be_kind_of DateTime
    bucket.api_url.must_equal "https://www.googleapis.com/storage/v1/b/#{bucket_name}"
    bucket.location.must_be_kind_of String
    bucket.logging_bucket.must_be :nil?
    bucket.logging_prefix.must_be :nil?
    bucket.storage_class.must_equal "STANDARD"
    bucket.versioning?.must_be :nil?
    bucket.website_main.must_be :nil?
    bucket.website_404.must_be :nil?

    bucket.cors.each do |cors|
      cors.must_be_kind_of Gcloud::Storage::Bucket::Cors::Rule
      cors.frozen?.must_equal true
    end
    bucket.cors.frozen?.must_equal true
  end

  it "sets and updates cors rules" do
    bucket.cors do |c|
      c.add_rule ["http://example.org", "https://example.org"],
                 "*",
                 headers: ["X-My-Custom-Header"],
                 max_age: 300
    end

    bucket.cors.wont_be :empty?
    bucket.cors.last.origin.must_equal ["http://example.org", "https://example.org"]
    bucket.cors.last.methods.must_equal ["*"]
    bucket.cors.last.headers.must_equal ["X-My-Custom-Header"]
    bucket.cors.last.max_age.must_equal 300

    bucket.reload!

    bucket.cors do |c|
      c.last.origin << "https://example.com"
      c.last.methods = ["PUT"]
      c.last.headers << "X-Another-Custom-Header"
      c.last.max_age = 600
    end

    bucket.reload!

    bucket.cors.last.origin.must_equal ["http://example.org", "https://example.org", "https://example.com"]
    bucket.cors.last.methods.must_equal ["PUT"]
    bucket.cors.last.headers.must_equal ["X-My-Custom-Header", "X-Another-Custom-Header"]
    bucket.cors.last.max_age.must_equal 600
  end

  it "does not error when getting a file that does not exist" do
    random_bucket = storage.bucket "#{bucket_name}_does_not_exist"
    random_bucket.must_be :nil?
  end
end
