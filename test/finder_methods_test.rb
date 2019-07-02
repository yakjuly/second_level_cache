# frozen_string_literal: true

require "test_helper"

class FinderMethodsTest < ActiveSupport::TestCase
  def setup
    @user = User.create name: "csdn", email: "test@csdn.com"
    @book = @user.books.create
  end

  def test_should_find_without_cache
    SecondLevelCache.cache_store.clear
    assert_equal @user, User.find(@user.id)
  end

  def test_should_find_with_string_id
    SecondLevelCache.cache_store.clear
    assert_equal @user, User.find(@user.id.to_s)
    assert_no_queries do
      assert_equal @user, User.find(@user.id.to_s)
    end
  end

  def test_should_find_with_has_many
    @book.write_second_level_cache
    assert_no_queries do
      assert_equal @book, @user.books.find(@book.id)
    end
  end

  def test_should_find_with_cache
    @user.write_second_level_cache
    assert_no_queries do
      assert_equal @user, User.find(@user.id)
    end
  end

  def test_should_find_with_condition
    @user.write_second_level_cache
    assert_no_queries do
      assert_equal @user, User.where(name: @user.name).find(@user.id)
    end
  end

  def test_should_not_find_from_cache_when_select_speical_columns
    @user.write_second_level_cache
    only_id_user = User.select("id").find(@user.id)
    assert_raises(ActiveModel::MissingAttributeError) do
      only_id_user.name
    end
  end

  def test_without_second_level_cache
    @user.name = "NewName"
    @user.write_second_level_cache
    User.without_second_level_cache do
      @from_db = User.find(@user.id)
    end
    refute_equal @user.name, @from_db.name
  end

  def test_where_and_first_should_with_cache
    @user.write_second_level_cache
    assert_no_queries do
      assert_equal @user, User.unscoped.where(id: @user.id).first
    end
  end

  def test_where_and_last_should_with_cache
    @user.write_second_level_cache
    assert_no_queries do
      assert_equal @user, User.unscoped.where(id: @user.id).last
    end
  end

  def test_should_not_write_cache_for_first
    @user = User.select("id").first
    @user = User.find(@user.id)
    assert_equal "csdn", @user.name
  end
end
