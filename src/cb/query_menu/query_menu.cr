require "ecr"
require "file_utils"

require "./query"

module CB::QueryMenu
  class Menu
    private property queries : Hash(String, Array(Query)) = Hash(String, Array(Query)).new([] of Query)
    private property path : String = ""

    def render(cluster : CB::Model::Cluster) : String
      temp_dir = "/tmp/crunchy/cli/#{cluster.name}-#{cluster.id}-queries"
      FileUtils.mkdir_p(temp_dir) unless File.exists? temp_dir

      # Aggregate all queries and group them by category in alphabetical order.
      @queries = Query.all.map(&.new(temp_dir))
        .sort_by!(&.category.order)
        .group_by(&.category.name)

      # Write the queries to the filesystem.
      @queries.each_value { |queries| queries.each(&.write) }

      # Render the menu file.
      @path = File.join(temp_dir, "menu.psql")
      query_menu = File.open(@path, mode: "w") do |menu|
        menu << ECR.render __DIR__ + "/menu.psql.ecr"
      end

      "\\set menu '\\\\i #{query_menu.path} '"
    end
  end
end
