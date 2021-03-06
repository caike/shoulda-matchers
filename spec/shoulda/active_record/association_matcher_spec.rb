require 'spec_helper'

describe Shoulda::Matchers::ActiveRecord::AssociationMatcher do

  context "belong_to" do
    before do
      @matcher = belong_to(:parent)
    end

    it "should accept a good association with the default foreign key" do
      define_model :parent
      define_model :child, :parent_id => :integer do
        belongs_to :parent
      end
      Child.new.should @matcher
    end

    it "should reject a nonexistent association" do
      define_model :child
      Child.new.should_not @matcher
    end

    it "should reject an association of the wrong type" do
      define_model :parent, :child_id => :integer
      child_class = define_model :child do
        has_one :parent
      end
      Child.new.should_not @matcher
    end

    it "should reject an association that has a nonexistent foreign key" do
      define_model :parent
      define_model :child do
        belongs_to :parent
      end
      Child.new.should_not @matcher
    end

    it "should accept an association with an existing custom foreign key" do
      define_model :parent
      define_model :child, :guardian_id => :integer do
        belongs_to :parent, :foreign_key => 'guardian_id'
      end
      Child.new.should @matcher
    end

    it "should accept a polymorphic association" do
      define_model :child, :parent_type => :string,
                           :parent_id   => :integer do
        belongs_to :parent, :polymorphic => true
      end
      Child.new.should @matcher
    end

    it "should accept an association with a valid :dependent option" do
      define_model :parent
      define_model :child, :parent_id => :integer do
        belongs_to :parent, :dependent => :destroy
      end
      Child.new.should @matcher.dependent(:destroy)
    end

    it "should reject an association with a bad :dependent option" do
      define_model :parent
      define_model :child, :parent_id => :integer do
        belongs_to :parent
      end
      Child.new.should_not @matcher.dependent(:destroy)
    end

    context 'with :options' do
      it "should reject a nonexistent association" do
        define_model :grade
        Grade.new.should_not belong_to(:gradeable, :polymorphic => false)
      end

      it "should accept a good association matching correct options" do
        create_table(:grades) do |t|
          t.references :child
          t.references :gradeable, :polymorphic => true
        end
        define_model_class :grade do
          belongs_to :gradeable, :polymorphic => true
        end
        Grade.new.should belong_to(:gradeable, :polymorphic => true)
      end

      it "should accept a good association without matching options" do
        create_table(:grades) do |t|
          t.references :child
          t.references :gradeable, :polymorphic => true
        end
        define_model_class :grade do
          belongs_to :gradeable, :polymorphic => true
        end
        Grade.new.should belong_to(:gradeable)
      end

      it "should reject an association with incorrect matching options" do
        create_table(:grades) do |t|
          t.references :child
          t.references :gradeable, :polymorphic => true
        end
        define_model_class :grade do
          belongs_to :gradeable, :polymorphic => true
        end
        Grade.new.should_not belong_to(:gradeable, :polymorphic => false)
      end
    end
  end

  context "have_many" do
    before do
      @matcher = have_many(:children)
    end

    it "should accept a valid association without any options" do
      define_model :child, :parent_id => :integer
      define_model :parent do
        has_many :children
      end
      Parent.new.should @matcher
    end

    it "should accept a valid association with a :through option" do
      define_model :child
      define_model :conception, :child_id  => :integer,
                                :parent_id => :integer do
        belongs_to :child
      end
      define_model :parent do
        has_many :conceptions
        has_many :children, :through => :conceptions
      end
      Parent.new.should @matcher
    end

    it "should accept a valid association with an :as option" do
      define_model :child, :guardian_type => :string,
                           :guardian_id   => :integer
      define_model :parent do
        has_many :children, :as => :guardian
      end
      Parent.new.should @matcher
    end

    it "should reject an association that has a nonexistent foreign key" do
      define_model :child
      define_model :parent do
        has_many :children
      end
      Parent.new.should_not @matcher
    end

    it "should reject an association with a bad :as option" do
      define_model :child, :caretaker_type => :string,
                           :caretaker_id   => :integer
      define_model :parent do
        has_many :children, :as => :guardian
      end
      Parent.new.should_not @matcher
    end

    it "should reject an association that has a bad :through option" do
      define_model :child, :parent_id => :integer
      define_model :parent do
        has_many :children
      end
      @matcher.through(:conceptions).matches?(Parent.new).should be_false
      @matcher.failure_message.should =~ /does not have any relationship to conceptions/
    end

    it "should reject an association that has the wrong :through option" do
      define_model :child
      define_model :conception, :child_id  => :integer,
                                :parent_id => :integer do
        belongs_to :child
      end
      define_model :parent do
        has_many :conceptions
        has_many :relationships
        has_many :children, :through => :conceptions
      end
      @matcher.through(:relationships).matches?(Parent.new).should be_false
      @matcher.failure_message.should =~ /through relationships, but got it through conceptions/
    end

    it "should accept an association with a valid :dependent option" do
      define_model :child, :parent_id => :integer
      define_model :parent do
        has_many :children, :dependent => :destroy
      end
      Parent.new.should @matcher.dependent(:destroy)
    end

    it "should reject an association with a bad :dependent option" do
      define_model :child, :parent_id => :integer
      define_model :parent do
        has_many :children
      end
      Parent.new.should_not @matcher.dependent(:destroy)
    end
  end

  context "have_one" do
    before do
      @matcher = have_one(:detail)
    end

    it "should accept a valid association without any options" do
      define_model :detail, :person_id => :integer
      define_model :person do
        has_one :detail
      end
      Person.new.should @matcher
    end

    it "should accept a valid association with an :as option" do
      define_model :detail, :detailable_id   => :integer,
                            :detailable_type => :string
      define_model :person do
        has_one :detail, :as => :detailable
      end
      Person.new.should @matcher
    end

    it "should reject an association that has a nonexistent foreign key" do
      define_model :detail
      define_model :person do
        has_one :detail
      end
      Person.new.should_not @matcher
    end

    it "should reject an association with a bad :as option" do
      define_model :detail, :detailable_id   => :integer,
                            :detailable_type => :string
      define_model :person do
        has_one :detail, :as => :describable
      end
      Person.new.should_not @matcher
    end

    it "should accept an association with a valid :dependent option" do
      define_model :detail, :person_id => :integer
      define_model :person do
        has_one :detail, :dependent => :destroy
      end
      Person.new.should @matcher.dependent(:destroy)
    end

    it "should reject an association with a bad :dependent option" do
      define_model :detail, :person_id => :integer
      define_model :person do
        has_one :detail
      end
      Person.new.should_not @matcher.dependent(:destroy)
    end
  end

  context "have_and_belong_to_many" do
    before do
      @matcher = have_and_belong_to_many(:relatives)
    end

    it "should accept a valid association" do
      define_model :relatives
      define_model :person do
        has_and_belongs_to_many :relatives
      end
      define_model :people_relative, :person_id   => :integer,
                                     :relative_id => :integer
      Person.new.should @matcher
    end

    it "should reject a nonexistent association" do
      define_model :relatives
      define_model :person
      define_model :people_relative, :person_id   => :integer,
                                     :relative_id => :integer
      Person.new.should_not @matcher
    end

    it "should reject an association with a nonexistent join table" do
      define_model :relatives
      define_model :person do
        has_and_belongs_to_many :relatives
      end
      Person.new.should_not @matcher
    end

    it "should reject an association of the wrong type" do
      define_model :relatives, :person_id => :integer
      define_model :person do
        has_many :relatives
      end
      Person.new.should_not @matcher
    end
  end

end
