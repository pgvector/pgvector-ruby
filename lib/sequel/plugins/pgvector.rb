module Sequel
  module Plugins
    module Pgvector
      def self.configure(model, *columns)
        model.vector_columns = columns.to_h { |c| [c.to_sym, {}] }
      end

      module ClassMethods
        attr_accessor :vector_columns

        def nearest_neighbors(column, value, distance:)
          value = ::Pgvector.encode(value) unless value.is_a?(String)
          quoted_column = dataset.quote_identifier(column)
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

          neighbor_distance =
            if distance == "inner_product"
              "(#{quoted_column} #{operator} ?) * -1"
            else
              "#{quoted_column} #{operator} ?"
            end

          select_append(Sequel.lit("#{neighbor_distance} AS neighbor_distance", value))
            .exclude(column => nil)
            .order(Sequel.lit("#{quoted_column} #{operator} ?", value))
        end

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
      end
    end
  end
end
