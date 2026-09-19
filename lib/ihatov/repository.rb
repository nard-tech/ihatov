# frozen_string_literal: true

module Ihatov
  # An immutable dictionary. Loading requires no network access.
  # @api private
  class Repository
    def self.load(directory)
      Loader.new(directory).load
    end

    def initialize(collections)
      @collections = collections.transform_values { |items| items.dup.freeze }.freeze
      freeze
    end

    def items(category)
      @collections.fetch(category)
    end
  end

  # Two passes resolve references even across authors or forward declarations.
  # @api private
  class Loader
    def initialize(directory)
      @directory = directory
      @authors = []
      @works = []
      @definitions = Schema::CATEGORIES.to_h { |category| [category, {}] }
      @relations = Schema::CATEGORIES.to_h { |category| [category, []] }
    end

    def load
      read_authors
      check_work_files
      @authors.each { |author| read_works(author) }
      collections = { authors: @authors, works: @works.sort_by(&:sort_key) }
      Schema::CATEGORIES.each { |category| collections[category.to_sym] = build_items(category) }
      Repository.new(collections)
    end

    private

    def read_authors
      data = DictionaryYAML.read(File.join(@directory, 'authors.yml'))
      Schema.mapping(data, allowed: ['authors'], required: ['authors'])
      Schema.array(data['authors'], 'authors').each do |row|
        Schema.author(row)
        raise DataError, "duplicate author id: #{row['id']}" if @authors.any? { |author| author.id == row['id'] }

        @authors << Author.new(id: row['id'], family_name: row['family_name'], given_name: row['given_name'])
      end
    end

    def check_work_files
      expected = @authors.map { |author| "#{author.id}.yml" }
      actual = Dir.glob(File.join(@directory, 'works', '*.yml')).map { |path| File.basename(path) }
      unexpected = actual - expected
      raise DataError, "unknown author files: #{unexpected.join(', ')}" unless unexpected.empty?
    end

    def read_works(author)
      path = File.join(@directory, 'works', "#{author.id}.yml")
      data = DictionaryYAML.read(path)
      Schema.mapping(data, allowed: ['works'], required: ['works'])
      Schema.array(data['works'], 'works').each do |row|
        Schema.work(row)
        raise DataError, "duplicate work id: #{row['id']}" if @works.any? { |work| work.id == row['id'] }

        work = build_work(row, author)
        @works << work
        Schema::CATEGORIES.each { |category| register(row.fetch(category, []), category, work) }
      end
    end

    def build_work(row, author)
      edition = row['edition']
      adopted = Edition.new(aozora_id: edition['aozora_id'], url: edition['url'], bibliography: edition['bibliography'])
      Work.new(id: row['id'], title: row['title'], author: author, edition: adopted, order: @works.length,
               announced_year: row['announced_year'], published_year: row['published_year'])
    end

    def register(rows, category, work)
      rows.each do |row|
        Schema.item(row, category)
        id = row['ref'] || row['id']
        unless row.key?('ref')
          raise DataError, "duplicate #{category} id: #{id}" if @definitions[category].key?(id)

          @definitions[category][id] = row
        end
        source = Source.new(work: work, location: row['location'], source_url: row['source_url'])
        @relations[category] << [id, source]
      end
    end

    def build_items(category)
      definitions = @definitions[category]
      sources = Hash.new { |hash, id| hash[id] = [] }
      @relations[category].each do |id, source|
        raise DataError, "unresolved #{category} reference: #{id}" unless definitions.key?(id)

        sources[id] << source
      end
      # Relation order, rather than definition location, also orders shared items.
      sources.map { |id, relations| build_item(definitions.fetch(id), category, relations) }
             .each_with_index.sort_by { |item, index| [*item.work.sort_key, index] }.map(&:first)
    end

    def build_item(row, category, sources)
      metadata = { id: row['id'], sources: sources }
      return build_place(row, metadata) if category == 'places'

      metadata[:content_warnings] = row.fetch('content_warnings', [])
      case category
      when 'quotes' then build_quote(row, metadata)
      when 'beings' then build_being(row, metadata)
      when 'onomatopoeias' then Onomatopoeia.new(row['text'], **metadata)
      end
    end

    def build_place(row, metadata)
      coordinates = row['coordinates']&.transform_keys(&:to_sym)&.transform_values(&:to_f)
      Place.new(row['name'], real: row['real'], coordinates: coordinates, **metadata)
    end

    def build_quote(row, metadata)
      case row['kind']
      when 'poem' then Quote::Poem.new(row['text'], **metadata)
      when 'tanka' then Quote::Tanka.new(row['text'], **metadata)
      when 'haiku' then Quote::Haiku.new(row['text'], **metadata)
      when 'passage' then Quote::Passage.new(row['text'], **metadata)
      end
    end

    def build_being(row, metadata)
      case row['kind']
      when 'person' then Person.new(row['name'], **metadata)
      when 'character' then Character.new(row['name'], **metadata)
      when 'creature' then Creature.new(row['name'], **metadata)
      end
    end
  end
end
