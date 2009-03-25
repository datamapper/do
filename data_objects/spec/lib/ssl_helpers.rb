module SSLHelpers

  def ssl_certs_dir
    @ssl_certs_dir ||= Pathname(__FILE__).dirname.join('ssl_certs').to_s
  end

  def ssl_config
    @ssl_config ||= {
      :ca_cert     => ssl_certs_dir / 'ca-cert.pem',
      :ca_key      => ssl_certs_dir / 'ca-cert.pem',
      :server_key  => ssl_certs_dir / 'server-key.pem',
      :server_cert => ssl_certs_dir / 'server-cert.pem',
      :client_key  => ssl_certs_dir / 'client-key.pem',
      :client_cert => ssl_certs_dir / 'client-cert.pem',
      :cipher      => 'AES128-SHA'
    }
  end

end
