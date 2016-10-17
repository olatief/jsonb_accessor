# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor::QueryBuilder do
  describe ".jsonb_contains" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: "ignored") }
    subject { Product.all }

    it "is a collection of records that match the query" do
      query = subject.jsonb_contains(:options, title: title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_contains(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_contains(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  describe "#jsonb_is" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: title, rank: nil) }
    subject { Product.all }

    it "is a collection of records with the same json" do
      query = subject.jsonb_is(:options, title: title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_is(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_is(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  context "jsonb_number_query" do
    let!(:high_rank_record) { Product.create!(rank: 5) }
    let!(:middle_rank_record) { Product.create!(rank: 4) }
    let!(:low_rank_record) { Product.create!(rank: 0) }
    subject { Product.all }

    context "greater than" do
      it "is matching records" do
        query = subject.jsonb_number_query(:options, :rank, :>, middle_rank_record.rank)
        expect(query).to exist
        expect(query).to eq([high_rank_record])
      end
    end

    context "less than" do
      it "is matching records" do
        query = subject.jsonb_number_query(:options, :rank, :<, middle_rank_record.rank)
        expect(query).to exist
        expect(query).to eq([low_rank_record])
      end
    end

    context "less than or equal to" do
      it "is matching records" do
        query = subject.jsonb_number_query(:options, :rank, :<=, middle_rank_record.rank)
        expect(query).to exist
        expect(query).to match_array([low_rank_record, middle_rank_record])
      end
    end

    context "greater than or equal to" do
      it "is matching records" do
        query = subject.jsonb_number_query(:options, :rank, :>=, middle_rank_record.rank)
        expect(query).to exist
        expect(query).to match_array([high_rank_record, middle_rank_record])
      end
    end
  end
end
