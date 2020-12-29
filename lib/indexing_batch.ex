defmodule Bonfire.TaxonomySeeder.IndexingBatch do
  use ActivityPubWeb, :controller

  import Bonfire.Common.Config, only: [repo: 0]

  @tags_index_name "taxonomy_tags"

  def batch() do
    Bonfire.Search.Indexer.init_index(@tags_index_name)

    {:ok, tags} = repo().query("WITH RECURSIVE taxonomy_tags_tree AS
    (SELECT id, name, parent_tag_id, CAST(name As varchar(1000)) As name_crumbs, summary
    FROM taxonomy_tag
    WHERE parent_tag_id is null
    UNION ALL
    SELECT si.id,si.name,
      si.parent_tag_id,
      CAST(sp.name_crumbs || '->' || si.name As varchar(1000)) As name_crumbs,
      si.summary
    FROM taxonomy_tag As si
      INNER JOIN taxonomy_tags_tree AS sp
      ON (si.parent_tag_id = sp.id)
    )
    SELECT id, name, name_crumbs, summary
    FROM taxonomy_tags_tree
    ORDER BY name_crumbs;
    ")

    # results = []

    for item <- tags.rows do
      [id, name, name_crumbs, summary] = item
      # obj = %{id: id, name: name, name_crumbs: name_crumbs, summary: summary}

      ## add to search index as is
      # Bonfire.Search.Indexer.index_objects(obj, @tags_index_name, false)

      ## import into Categories
      Bonfire.TaxonomySeeder.TaxonomyTags.maybe_make_category(nil, id)

      # results = results ++ [obj]
    end

    # Search.Indexer.index_objects(results, @tags_index_name)
  end
end
