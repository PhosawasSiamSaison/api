server '10.0.3.20', roles: %w(app web db), user: 'jbcdev', ssh_options: {
  keys: %w(~/.ssh/id_rsa),
  forward_agent: true,
  auth_methods: %w(publickey),
  port: 29292
}
