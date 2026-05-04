require "./action"
require "./table"

module CB
  class SavedQueryList < APIAction
    eid_setter cluster_id
    format_setter format
    bool_setter? no_header

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
      end
    end

    def run
      validate
      queries = client.get_saved_queries cluster_id

      if queries.empty?
        output.puts "no saved queries"
        return
      end

      case @format
      when Format::JSON
        output << queries.to_pretty_json << '\n'
      else
        table = Table::TableBuilder.new(border: :none) do
          columns do
            add "ID"
            add "Name"
            add "Query"
          end

          header unless no_header

          queries.each do |q|
            row [q.id, q.name, truncate_sql(q.sql)]
          end
        end

        output << table.render << '\n'
      end
    end

    private def truncate_sql(sql : String?) : String
      return "" if sql.nil?
      collapsed = sql.gsub(/\s+/, " ").strip
      collapsed.size > 30 ? "#{collapsed[0, 50]}..." : collapsed
    end
  end

  class SavedQueryExport < APIAction
    eid_setter cluster_id
    eid_setter query_id
    property file : String?

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "query" unless query_id
      end
    end

    def run
      validate
      query = client.get_saved_query query_id

      filename = @file || "#{query.name.gsub(/[^a-zA-Z0-9_\-]/, "_")}.sql"
      File.write(filename, query.sql)
      output << "exported " << query.name << " to " << filename << '\n'
    end
  end

  class SavedQueryImport < APIAction
    eid_setter cluster_id
    property file : String?
    property name : String?

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "file" unless file
        missing << "name" unless name
      end
    end

    def run
      validate
      sql = File.read(@file.to_s)

      query = client.create_saved_query({
        cluster_id:   cluster_id,
        name:         @name,
        sql:          sql,
        skip_enqueue: true,
      })

      output << "created saved query " << query.id << '\n'
    end
  end

  class SavedQueryDestroy < APIAction
    eid_setter cluster_id
    eid_setter query_id

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "query" unless query_id
      end
    end

    def run
      validate
      client.destroy_saved_query query_id
      output << "saved query destroyed" << '\n'
    end
  end
end
