class AddUserToJobs < ActiveRecord::Migration[8.0]
  def change
    # Nullable since existing Job rows have no recorded owner - Public::ResourcesController
    # treats a null user_id the same as a mismatched one (nobody can "adopt" a pre-existing,
    # unowned job), so there's no need to backfill.
    add_reference :jobs, :user, null: true, foreign_key: true, index: true
  end
end
