module Sequel
  module Plugins
    module Pgvector
      def self.configure(model, *columns)
        model.vector_columns ||= {}
        columns.each do |column|
          model.vector_columns[column.to_sym] = {}
        end
      end

      module DatasetMethods
        def nearest_neighbors(column, value, distance:)
          value = ::Pgvector.encode(value) unless value.is_a?(String)
          quoted_column = quote_identifier(column)
          distance = distance.to_s

          operator =
            case distance
            when "inner_product"
              "<#>"
            when "cosine"
              "<=>"
            when "euclidean"
              "<->"
            end

          raise ArgumentError, "Invalid distance: #{distance}" unless operator

          order = "#{quoted_column} #{operator} ?"

          neighbor_distance =
            if distance == "inner_product"
              "(#{order}) * -1"
            else
              order
            end

          select_append(Sequel.lit("#{neighbor_distance} AS neighbor_distance", value))
            .exclude(column => nil)
            .order(Sequel.lit(order, value))
        end
      end

      module ClassMethods
        attr_accessor :vector_columns

        Sequel::Plugins.def_dataset_methods(self, :nearest_neighbors)

        Plugins.inherited_instance_variables(self, :@vector_columns => :dup)
      end

      module InstanceMethods
        def nearest_neighbors(column, **options)
          column = column.to_sym
          # important! check if neighbor attribute before calling send
          raise ArgumentError, "Invalid column" unless self.class.vector_columns[column]

          self.class
            .nearest_neighbors(column, self[column], **options)
            .exclude(primary_key => self[primary_key])
        end

        def []=(k, v)
          if self.class.vector_columns.key?(k.to_sym) && !v.is_a?(String)
            super(k, ::Pgvector.encode(v))
          else
            super
          end
        end

        def [](k)
          if self.class.vector_columns.key?(k.to_sym)
            ::Pgvector.decode(super)
          else
            super
          end
        end
      end
    end
  end
end
