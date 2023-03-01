require "./action"
require "../types/tree"

class CB::List < CB::APIAction
  format_setter format

  eid_setter team_id

  property no_header : Bool = false

  def run
    # If the format is tree, then we don't need to flatten the results.
    flatten = !(format == CB::Format::Tree)
    teams = client.get_teams
    clusters = client.get_clusters(teams, flatten)

    data = Hash(String, Array(CB::Client::Cluster)).new do |hash, key|
      hash[key] = [] of CB::Client::Cluster
    end

    clusters.each do |c|
      team_name = teams.find { |t| t.id == c.team_id }.try &.name || c.team_id
      data[team_name] << c
    end

    case @format
    when CB::Format::Default, CB::Format::Table
      output_table(data)
    when CB::Format::Tree
      output_tree(data)
    end
  end

  private def output_tree(data)
    trees = [] of CB::Types::Tree(String)

    data.each do |team, clusters|
      team_name = "#{team.colorize.t_alt}"
      tree = CB::Types::Tree.new(team_name)
      clusters.each { |cluster| dive(tree, cluster) }
      trees << tree
    end

    trees.each do |tree|
      next if !tree.has_children?
      renderer = CB::Tree::Renderer.new(tree)
      output << renderer.render
      output << '\n' unless tree == trees.last?
    end
  end

  # Dive down into the list of clusters and add all replicas to the proper
  # level of the tree.
  private def dive(tree, cluster)
    new_tree = CB::Types::Tree.new("#{cluster.name} (#{cluster.id})")
    cluster.replicas.try &.each { |replica| dive(new_tree, replica) }
    tree << new_tree
  end

  private def output_table(data)
    table = Table::TableBuilder.new(border: :none) do
      columns do
        add "ID"
        add "Name"
        add "Team"
      end

      header unless no_header

      data.each do |team, clusters|
        clusters.each do |cluster|
          row [
            cluster.id.colorize.t_id,
            cluster.name.colorize.t_name,
            team.colorize.t_alt,
          ]
        end
      end
    end

    output << table.render << '\n'
  end
end
