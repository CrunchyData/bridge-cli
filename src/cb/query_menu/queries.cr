require "./query"

module CB::QueryMenu
  # Here we define the builtin queries that are included when using the `:menu`
  # command in `psql`.
  #
  # Each query MUST do the following:
  #   * Extend `CB::QueryMenu::Query`
  #   * Define a `Metadata` annotation that includes the `label` and `category`
  #     for the query.
  #   * Embed the SQL for the query. This is done using the `embed_sql` macro.
  #
  # Example:
  # ```
  # @[Metadata(label: "Example query label", category: Category.new("Example", 1))]
  # struct Foo < Query
  #   ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/example.sql")
  # end
  # ```

  #
  # Cache
  #

  @[Metadata(label: "Cache and index hit rates", category: CATEGORY_CACHE)]
  struct CacheHitRates < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/cache_hit_rates.sql")
  end

  #
  # Connection Management
  #

  @[Metadata(label: "Connection count by state", category: CATEGORY_CONNECTION_MANAGEMENT)]
  struct ConnectionManagementCountByStates < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/connection_management_count_by_state.sql")
  end

  @[Metadata(label: "Connection count by user and application", category: CATEGORY_CONNECTION_MANAGEMENT)]
  struct ConnectionManagementCountByUser < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/connection_management_count_by_user_and_application.sql")
  end

  #
  # Extensions Queries
  #

  @[Metadata(label: "Available extensions", category: CATEGORY_EXTENSIONS)]
  struct AvailableExtensions < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/extensions_available.sql")
  end

  @[Metadata(label: "Installed extensions", category: CATEGORY_EXTENSIONS)]
  struct InstalledExtensions < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/extensions_installed.sql")
  end

  #
  # Index Queries
  #

  @[Metadata(label: "Duplicate indexes", category: CATEGORY_INDEXES)]
  struct IndexesDuplicates < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/indexes_duplicates.sql")
  end

  @[Metadata(label: "List of indexes", category: CATEGORY_INDEXES)]
  struct IndexesList < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/indexes_list.sql")
  end

  @[Metadata(label: "Unused indexes", category: CATEGORY_INDEXES)]
  struct IndexesUnused < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/indexes_unused.sql")
  end

  #
  # Locks Queries
  #

  @[Metadata(label: "Blocking queries", category: CATEGORY_LOCKS)]
  struct LocksBlockingQueries < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/locks_blocking_queries.sql")
  end

  #
  # Query Performance Queries
  #

  @[Metadata(label: "Queries consuming the most system time", category: CATEGORY_QUERY_PERFORMANCE)]
  struct MostConsumingQueries < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/query_performance_most_consuming_system_time.sql")
  end

  @[Metadata(label: "Queries running over 1 minute", category: CATEGORY_QUERY_PERFORMANCE)]
  struct OverOneMinuteQueries < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/query_performance_over_one_minute.sql")
  end

  @[Metadata(label: "Slowest average queries", category: CATEGORY_QUERY_PERFORMANCE)]
  struct SlowestAverageQueries < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/query_performance_slowest_average.sql")
  end

  #
  # Size Information Queries
  #

  @[Metadata(label: "Database sizes", category: CATEGORY_SIZE_INFORMATION)]
  struct DatabaseSize < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/size_information_database_size.sql")
  end

  @[Metadata(label: "Table sizes", category: CATEGORY_SIZE_INFORMATION)]
  struct TableSize < Query
    ::CB::QueryMenu.embed_sql("#{__DIR__}/sql/size_information_table_size.sql")
  end
end
