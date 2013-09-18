class Spree::Menu < ActiveRecord::Base

  SP_CACHE_PREFIX = "sp_menu_"
  SP_CACHE_KEYS = "sp_menu_keys"

  attr_accessible :title

  has_many :pages, class_name: "Spree::Page", foreign_key: "spree_menu_id", dependent: :destroy

  validates :title, uniqueness: true

  after_save :clear_menu_cache

  def options_for_select(page_id=nil)
    key = "#{SP_CACHE_PREFIX}options_for_select_#{self.id}_#{page_id}"
    Rails.cache.fetch(key) do
      # add this to our cache of cache keys for deletion
      self.class.cache_key(key)
      # used for admin forms - shows all items
      q = pages.select('id, title, menu_item_title, slug, foreign_link, parent_id, visible')
      arr = flatten(q.as_json(root: false))
      r = []
      arr.each do |item|
        option = ["#{'-' * item[:parents].length } #{item[:title]}#{ ' (not visible)' unless item[:is_visible]}", item[:id]]
        # page cannot be a descendent of itself, or of it's children
        option << { disabled: "disabled" } if page_id && (item[:id] == page_id || item[:parent_ids].include?(page_id))
        r << option
      end
      r
    end
  end

  def nested_items(*args)
    defaults = {
      only_visible: true,
      parent_id: nil,
      max_levels: 0,
      current_path: nil,
    }
    options = defaults.merge(args.extract_options!)

    key = "#{SP_CACHE_PREFIX}nested_items_#{self.id}_#{options[:only_visible]}_#{options[:parent_id]}_#{options[:max_levels]}_#{options[:current_path]}"
    Rails.cache.fetch(key) do
      # add this to our cache of cache keys for deletion
      self.class.cache_key(key)
      q = pages.select('id, title, menu_item_title, slug, foreign_link, parent_id, visible')
      q = q.visible if options[:only_visible]
      flatten(
        q.as_json(root: false),
        show_children: true,
        parent_id: options[:parent_id],
        max_levels: options[:max_levels],
        current_path: options[:current_path]
      )
    end
  end

  class << self
    def options_for_select
      opts = [['- no menu -', nil,]]
      opts += Spree::Menu.all.collect{ |i| [i.title, i.id] }
    end

    def cache_key(key)
      Rails.logger.debug("writing menu cache to #{key}")
      # workaround for lack of delete_matched functionality with memcached
      # tracks all of our menu cache keys so we can delete them later
      keys = Rails.cache.fetch(SP_CACHE_KEYS) do
        []
      end
      unless keys.include?(key)
        keys << key
        Rails.cache.write(SP_CACHE_KEYS, keys)
      end
    end

    def clear_caches
      keys = Rails.cache.read(SP_CACHE_KEYS) do
        []
      end
      keys.each do |key|
        Rails.cache.delete(key)
      end
      # and overwrite our keys
      Rails.cache.write(SP_CACHE_KEYS, [])
    end
  end

  private
  def flatten(arr, *args)
    defaults = {
      show_children: false,
      max_levels: 0,
      parent_id: nil,
      current_path: nil,

      parents: [],
      parent_ids: [],
    }
    options = defaults.merge(args.extract_options!)

    # NOTE: this loops arr.length * arr.length + arr.length times
    # not very efficient. would be better to splice items off as they're used.
    # tried using delete_if, but it didn't work consistently
    r = []
    arr.each do |page|
      page['is_on'] ||= false
      page['is_active'] ||= false
      if page['parent_id'] == options[:parent_id]
        this_r = {
          title: (page['menu_item_title'].present? ? page['menu_item_title'] : page['title']),
          id: page['id'],
          link: page['foreign_link'].present? ? page['foreign_link'] : "/#{page['slug']}",
          parents: options[:parents],
          parent_ids: options[:parent_ids],
          is_visible: page['visible'],
          is_on: page['is_on'],
          is_active: page['is_active'],
        }

        # RECURSION - clone to prevent dups
        this_options = options.clone
        this_options[:parents] += [this_r] # reference this so can set is_active later in the loop
        this_options[:parent_ids] += [this_r[:id]]

        if options[:current_path] && this_r[:link] == options[:current_path]
          this_r[:parents].each do |p|
            p[:is_active] = true
          end
          this_r[:is_active] = true
          this_r[:is_on] = true
        end

        # if we've hit our max depth, move along
        next if this_options[:max_levels] > 0 && this_options[:parents].length > this_options[:max_levels]

        this_options[:parent_id] = page['id']
        if this_options[:show_children]
          this_r[:children] = flatten(arr, this_options)
          r << this_r
        else
          r << this_r
          r += flatten(arr, this_options)
        end
      end
    end
    r
  end

  def clear_menu_cache
    Spree::Menu.clear_caches
    true
  end

end
