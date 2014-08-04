require 'helper'
describe Epiphy::Entity do
  before do
    class Car
      include Epiphy::Entity
    end

    class Book
      include Epiphy::Entity
      self.attributes = :title, :author
    end

    class NonFinctionBook < Book
    end

    class Camera
      include Epiphy::Entity
      attr_accessor :analog
    end
  end

  after do
    [:Car, :Book, :NonFinctionBook, :Camera].each do |const|
      Object.send(:remove_const, const)
    end
  end

  describe 'attributes' do
    let(:attributes) { [:id, :model] }

    it 'defines attributes' do
      Car.send(:attributes=, attributes)
      Car.send(:attributes).must_equal attributes
    end
  end

  describe '#initialize' do
    describe 'with defined attributes' do
      it 'accepts given attributes' do
        book = Book.new(title: "A Lover's Discourse: Fragments", author: 'Roland Barthes')

        book.instance_variable_get(:@title).must_equal  "A Lover's Discourse: Fragments"
        book.instance_variable_get(:@author).must_equal 'Roland Barthes'
      end

      it 'ignores unknown attributes' do
        book = Book.new(unknown: 'x')

        book.instance_variable_get(:@unknown).must_be_nil
      end

      it 'accepts given attributes for subclass' do
        book = NonFinctionBook.new(title: 'Refactoring', author: 'Martin Fowler')

        book.instance_variable_get(:@title).must_equal  'Refactoring'
        book.instance_variable_get(:@author).must_equal 'Martin Fowler'
      end
    end

    describe 'with a hash' do
      let (:hash1) { {:title => 'Da tinh kiem khach vo tinh kiem', :author => 'Co Long'} }
      let (:hash2) { {:title => 'Ba Vuong Thuong', :author => 'Co Long', :review => 'kurei'} }
      let (:hash3) { {'title' => 'Da Tinh Hoan', 'author' => 'Co Long', 'review' => 'kurei'} }

      it 'accepts given hash' do
        book = Book.new hash1
        book.title.must_equal hash1[:title]
        book.instance_variable_get(:@author).must_equal hash1[:author]
      end
      
      it 'ignore unknow attributes' do
        book = Book.new hash2
        book.instance_variable_get(:@review).must_be_nil
      end

      it 'accepts hash with key as string(not symbol)' do
        puts 'test accept hash with key as string'
        book = Book.new(hash3)
        pp hash3
        pp book
        book.author.must_equal 'Co Long'
        puts 'end'
      end
    end

    describe 'with undefined attributes' do
      it 'has default accessor for id' do
        camera = Camera.new
        camera.must_respond_to :id
        camera.must_respond_to :id=        
      end
      
      it 'is able to initialize an entity without given attributes' do
        camera = Camera.new
        camera.analog.must_be_nil
      end

      it 'is able to initialize an entity if it has the right accessors' do
        camera = Camera.new(analog: true)
        camera.analog.must_equal(true)
      end

      it "raises an error when the given attributes don't correspond to a known accessor" do
        -> { Camera.new(digital: true) }.must_raise(NoMethodError)
      end
    end
  end

  describe 'accessors' do
    it 'exposes getters for attributes' do
      book = Book.new(title: 'High Fidelity')

      book.title.must_equal 'High Fidelity'
    end

    it 'exposes setters for attributes' do
      book = Book.new
      book.title = 'A Man'

      book.instance_variable_get(:@title).must_equal 'A Man'
      book.title.must_equal 'A Man'
    end

    it 'exposes accessor for id' do
      book = Book.new
      book.id.must_be_nil

      book.id = 23
      book.id.must_equal 23
    end
  end

  describe '#==' do
    before do
      @book1 = Book.new
      @book1.id = 23

      @book2 = Book.new
      @book2.id = 23

      @book3 = Book.new
      @car   = Car.new
    end

    it 'returns true if they have the same class and id' do
      @book1.must_equal @book2
    end

    it 'returns false if they have the same class but different id' do
      @book1.wont_equal @book3
    end

    it 'returns false if they have different class' do
      @book1.wont_equal @car
    end
  end

end
