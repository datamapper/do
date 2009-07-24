require 'cgi'

module SSLHelpers

  CERTS_DIR = Pathname(__FILE__).dirname.join('ssl_certs').to_s

  CONFIG = OpenStruct.new
  CONFIG.ca_cert     = CERTS_DIR / 'ca-cert.pem'
  CONFIG.ca_key      = CERTS_DIR / 'ca-key.pem'
  CONFIG.server_cert = CERTS_DIR / 'server-cert.pem'
  CONFIG.server_key  = CERTS_DIR / 'server-key.pem'
  CONFIG.client_cert = CERTS_DIR / 'client-cert.pem'
  CONFIG.client_key  = CERTS_DIR / 'client-key.pem'
  CONFIG.cipher      = 'AES128-SHA'

  def self.query(*keys)
    keys.map { |key| "ssl[#{key}]=#{CGI::escape(CONFIG.send(key))}" }.join('&')
  end

end
