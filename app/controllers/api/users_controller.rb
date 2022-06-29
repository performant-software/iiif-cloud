class Api::UsersController < Api::BaseController
  search_attributes :name, :email

  protected

  def apply_filters(query)
    query = super

    query = filter_organization(query)

    query
  end

  private

  def filter_organization(query)
    return query unless params[:organization_id].present?

    query.where(
      UserOrganization
        .where(UserOrganization.arel_table[:user_id].eq(User.arel_table[:id]))
        .where(organization_id: params[:organization_id])
        .arel
        .exists
    )
  end
end
