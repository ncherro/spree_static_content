class Spree::Menu < ActiveRecord::Base

  attr_accessible :title

  has_many :pages, class_name: "Spree::Page", foreign_key: "spree_menu_id", dependent: :destroy

  def options_for_select(page_id=nil)
    # used for admin forms - shows all items
    q = pages.select('id, title, slug, foreign_link, parent_id, visible')
    arr = flatten(q.as_json(root: false))
    r = []
    arr.each do |item|
      option = ["#{'-' * item[:parents].length } #{item[:title]}#{ ' (not visible)' unless item[:visible]}", item[:id]]
      option << { disabled: "disabled" } if page_id && (item[:id] == page_id || item[:parent_ids].include?(page_id))
      r << option
    end
    r
  end

  def nested_items(*args)
    defaults = {
      only_visible: true,
      max_levels: 0,
      current_path: nil,
    }
    options = defaults.merge(args.extract_options!)

    q = pages.select('id, title, slug, foreign_link, parent_id, visible')
    q = q.visible if options[:only_visible]
    flatten(q.as_json(root: false), show_children: true, max_levels: options[:max_levels], current_path: options[:current_path])
  end

  class << self
    def options_for_select
      opts = [['- no menu -', nil,]]
      opts += Spree::Menu.all.collect{ |i| [i.title, i.id] }
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
          title: page['title'],
          id: page['id'],
          link: page['foreign_link'].present? ? page['foreign_link'] : "/#{page['slug']}",
          parents: options[:parents],
          parent_ids: options[:parent_ids],
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

end
