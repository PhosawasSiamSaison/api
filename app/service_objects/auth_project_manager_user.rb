class AuthProjectManagerUser
  def initialize(project_manager_user, password)
    @project_manager_user = project_manager_user
    @password = password
  end

  def call
    project_manager_user.present? && project_manager_user.authenticate(password).present?
  end

  private
  attr_reader :project_manager_user, :password

  def project_manager_user
    @project_manager_user
  end
end
