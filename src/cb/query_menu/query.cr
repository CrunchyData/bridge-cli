require "base64"

module CB::QueryMenu
  # Metadata annoation for a query.
  #
  # A `Query` must have a `label` and `category` field defined using this
  # annotation.
  annotation Metadata; end

  # Category for a query, this is used for grouping and order queries in the
  # query menu.
  struct Category
    # The name of the category.
    getter name : String

    # The order that the category appears in the query menu.
    getter order : Int8

    def initialize(@name = "", @order = -1); end
  end

  # Query Categories.
  CATEGORY_CACHE                 = Category.new name: "Cache", order: 1
  CATEGORY_CONNECTION_MANAGEMENT = Category.new name: "Connection Management", order: 4
  CATEGORY_EXTENSIONS            = Category.new name: "Extensions", order: 7
  CATEGORY_INDEXES               = Category.new name: "Indexes", order: 5
  CATEGORY_LOCKS                 = Category.new name: "Locks", order: 6
  CATEGORY_QUERY_PERFORMANCE     = Category.new name: "Query Performance", order: 3
  CATEGORY_SIZE_INFORMATION      = Category.new name: "Size Information", order: 2

  @[Metadata(label: "", category: Category.new)]
  abstract struct Query
    getter dirname : String

    def initialize(@dirname); end

    def path
      File.join(dirname, sql_filename)
    end

    # Write the query to file.
    def write
      File.open(path, "w") { |file| file << Base64.decode_string(sql) }
    end

    def self.all
      {{
        Query.subclasses.map do |query|
          ann = query.annotation(Metadata)
          raise "#{query} is missing Metadata annotation" unless ann
          query
        end
      }}
    end

    # The category of the query. This value is defined by setting the `category`
    # field in the `Metadata` annotation.
    def category : Category
      {% if @type.annotation(Metadata)[:category] %}
        {{@type.annotation(Metadata)[:category]}}
      {% else %}
        {{raise "#{@type} must have a category."}}
      {% end %}
    end

    # The label of the query. This value is define by setting the `label` field
    # in the `Metadata` annotation.
    def label : String
      {% if @type.annotation(Metadata)[:label] %}
        {{ @type.annotation(Metadata)[:label] }}
      {% else %}
        {{raise "#{@type} must have a label."}}
      {% end %}
    end

    abstract def sql
    abstract def sql_filename
  end

  macro embed_sql(path)
    def sql
      {{ run("../../tools/embed_base64.cr", path).stringify }}
    end

    def sql_filename
      File.basename {{path}}
    end
  end
end
