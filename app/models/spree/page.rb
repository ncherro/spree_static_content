class Spree::Page < ActiveRecord::Base
  default_scope :order => "position ASC"

  belongs_to :menu, class_name: "Spree::Menu", foreign_key: "spree_menu_id"

  validates_presence_of :title
  validates_presence_of [:slug, :body], :if => :not_using_foreign_link?
  validates_presence_of :layout, :if => :render_layout_as_partial?

  validates :slug, :uniqueness => true, :if => :not_using_foreign_link?
  validates :foreign_link, :uniqueness => { :scope => :spree_menu_id }, :allow_blank => true

  scope :visible, where(:visible => true)

  before_validation :set_slug
  before_save :update_positions_and_slug
  after_save :clear_menu_cache

  attr_accessible :title, :slug, :body, :meta_title, :meta_keywords,
    :meta_description, :layout, :foreign_link, :position, :visible,
    :render_layout_as_partial, :parent_id, :spree_menu_id, :menu_item_title

  delegate :title, to: :menu, prefix: true, allow_nil: true

  def self.by_slug(slug)
    slug = StaticPage::remove_spree_mount_point(slug)
    pages = self.arel_table
    query = pages[:slug].eq(slug).or(pages[:slug].eq("/#{slug}"))
    self.where(query)
  end

  def initialize(*args)
    super(*args)

    last_page = Spree::Page.last
    self.position = last_page ? last_page.position + 1 : 0
  end

  def link
    foreign_link.blank? ? slug : foreign_link
  end

  class << self
    def options_for_select
      opts = []
      Spree::Page.all.each do |p|
      end
    end
  end

  private
  def update_positions_and_slug
    unless new_record?
      return unless prev_position = Spree::Page.find(self.id).position
      if prev_position > self.position
        Spree::Page.update_all("position = position + 1", ["? <= position AND position < ?", self.position, prev_position])
      elsif prev_position < self.position
        Spree::Page.update_all("position = position - 1", ["? < position AND position <= ?", prev_position,  self.position])
      end
    end

    true
  end

  def set_slug
    if self.slug.blank? && self.foreign_link.blank?
      o_s = self.title.parameterize
      s = o_s
      i = 0
      while Spree::Page.where(slug: s).count > 0
        i += 1
        s = "#{o_s}-#{i}"
      end
      self.slug = s
    end
    true
  end

  def not_using_foreign_link?
    foreign_link.blank?
  end

  def clear_menu_cache
    # detect changes to specific fields
    if self.title_changed? || self.menu_item_title_changed? || self.parent_id_changed? || self.spree_menu_id_changed?
      self.menu.purge_from_cache
    end
    true
  end
end
