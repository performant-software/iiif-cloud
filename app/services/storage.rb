class Storage
  def generate_name(project_name)
    # Replace spaces with dashes and convert all characters to lowercase
    name = project_name.parameterize(separator: '-')

    # If a project with this name already exists (possibly in another organization), append a count
    query = Project.where(bucket_name: name)
    if query.exists?
      name += query.count - 1
    end

    # Return the name
    name
  end
end
