# frozen_string_literal: true

require "test_helper"

class PolymorphicAssociationTest < ActiveSupport::TestCase
  def setup
    @user = User.create name: "csdn", email: "test@csdn.com"
  end

  def test_should_get_cache_when_use_polymorphic_association
    image = @user.images.create

    @user.write_second_level_cache
    assert_no_queries do
      assert_equal @user, image.imagable
    end
  end

  def test_should_write_polymorphic_association_cache
    image = @user.images.create
    assert_nil User.read_second_level_cache(@user.id)
    assert_equal @user, image.imagable
  end
end
