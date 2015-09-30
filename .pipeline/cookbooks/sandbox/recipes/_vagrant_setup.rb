directory '/etc/saml' do
  action :create
end

file '/etc/saml/saml_idp.pem' do
  content "fakesamlidp\nline2"
end

file '/etc/saml/saml_cert.pem' do
  content "fakesaml_cert\nline2"
end

file '/etc/saml/saml_private_key.pem' do
  content "fakesaml_private_key\nline2"
end

package 'git'

package 'nodejs'

package 'libpq-dev'

package 'sqlite3'
package 'libsqlite3-dev'

#this is to work around linking problems with the pg gem and openssl
#if the pg gem is built against an openssl library that doesn't match up
#with the openssl library baked into chef's ruby.... problems abound
#so install this ruby to fix up the linking
package 'software-properties-common'
execute 'apt-add-repository -y ppa:brightbox/ruby-ng'
execute 'apt-get -y update'
package 'ruby2.1'
package 'ruby2.1-dev'
execute 'gem install bundler'