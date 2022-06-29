class Api::OrganizationsController < Api::BaseController
  search_attributes :name, :location

  protected

  def apply_filters(query)
    query = super

    query = filter_user(query)

    query
  end

  private

  def filter_user(query)
    return query unless params[:user_id].present?

    query.where(
      UserOrganization
        .where(UserOrganization.arel_table[:organization_id].eq(Organization.arel_table[:id]))
        .where(user_id: params[:user_id])
        .arel
        .exists
    )
  end
end
