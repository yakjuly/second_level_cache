# frozen_string_literal: true

module SecondLevelCache
  module ActiveRecord
    module Associations
      class Preloader
        module BelongsTo
          def records_for(ids, &block)
            return super(ids, &block) unless reflection.is_a?(::ActiveRecord::Reflection::BelongsToReflection)
            return super(ids, &block) unless klass.second_level_cache_enabled?

            map_cache_keys = ids.map { |id| klass.second_level_cache_key(id) }
            records_from_cache = ::SecondLevelCache.cache_store.read_multi(*map_cache_keys)
            # NOTICE
            # Rails.cache.read_multi return hash that has keys only hitted.
            # eg. Rails.cache.read_multi(1,2,3) => {2 => hit_value, 3 => hit_value}
            hitted_ids = records_from_cache.map { |key, _| key.split("/")[2] }
            missed_ids = ids.map(&:to_s) - hitted_ids

            ::SecondLevelCache.logger.info "missed ids -> #{missed_ids.join(',')} | hitted ids -> #{hitted_ids.join(',')}"

            record_marshals = RecordMarshal.load_multi(records_from_cache.values)

            if missed_ids.empty?
              return SecondLevelCache::RecordRelation.new(record_marshals)
            end

            records_from_db = super(missed_ids, &block)
            records_from_db.map do |r|
              write_cache(r)
            end

            SecondLevelCache::RecordRelation.new(records_from_db + record_marshals)
          end

          private

          def write_cache(record)
            record.write_second_level_cache
          end
        end
      end
    end
  end
end
