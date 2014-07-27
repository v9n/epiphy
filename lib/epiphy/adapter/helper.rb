module Epiphy
  module Adapter
    class Rethinkdb
      # Execute a ReQL query
      #
      # @param object [RethinkDB::ReQL]
      def query(table, repository)
        raise ArgumentError, 'Missing query block' unless block_given? 
        if block_given?
          rql = get_table(table)
          yield(rql)
        end
        rql.run(@connection)
      end
      protected

      # The table name. 
      def collection
        params[:controller]
      end

      def get_table(table = nil)
        table ||= collection
        r.db('test').table(table)
      end

      # RethinkDB method related. Should be in its helper
      def insert_object
        get_table.insert(
          safe_params.merge(
            id: params[:id],
            created_at: Time.now,
            updated_at: Time.now
          ).merge(parents)
        ).run(@connection)
        :created
      end

      def update_object
        get_table.update(
          safe_params.merge(
            id: params[:id],
            updated_at: Time.now
          )
        ).run(@connection)
        :ok
      end

      def replace_object
        get_table.replace(
          safe_params.merge(
            id: params[:id],
            created_at: Time.now,
            updated_at: Time.now
          ).merge(parents)
        ).run(@connection)
        :ok
      end

      def delete_object
        get_table.get(params[:id]).delete(
          :durability => "hard", :return_vals => false
        ).run(@connection)
        :no_content
      end

      def sort(qry)
        ordering = params[:sort].split(",").map do |attr|
          if attr[0] == "-"
            r.desc(attr[1..-1].to_sym)
          else
            r.asc(attr.to_sym)
          end
        end

        qry.order_by(*ordering)
      end

      def select(qry)
        qry = qry.get_all(*params[:ids].split(",")) if params[:ids]
        qry
      end

      def parents
        params.select {|k,v| k.match(/\A[a-z0-9_]+_id\z/i) }.compact
      end

      def filter(qry)
        parents.empty? ? qry : qry.filter(parents)
      end

      def attrs
        [ :id ]
      end

      def get_range(qry)
        begin
          rhdr = request.headers[:HTTP_RANGE].split("=")

          if rhdr[0] == collection
            qry = qry[Range.new(*rhdr[1].split("-").map(&:to_i))]
          end
        rescue Exception => e
          puts e.message
          raise Exception.new(:bad_request)
        end
        qry
      end

      def get_records
        qry = get_table
        qry = sort(qry) if params[:sort]

        fields = if params[:fields]
                   params[:fields].split(",").map {|f| f.to_sym }.select do |field|
                     attrs.include? field
                   end
                 else
                   attrs
                 end

        qry = filter(select(qry)).pluck(fields)
        qry = get_range(qry) if request.headers[:HTTP_RANGE]

        qry.run(@connection).map do |record|
          record.merge(href: some_url(record["id"]))
        end
      end

      def get_object
        get_table.filter(parents.merge({id: params[:id]})).pluck(attrs).run(@connection).first
      end

    end
  end
end

