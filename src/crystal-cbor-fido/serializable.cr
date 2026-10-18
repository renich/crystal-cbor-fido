module Crystal::Cbor::Fido
  # Configures per-field serialization key mapping and exclusion for `Serializable` types.
  annotation Field
  end

  # Internal type-conversion bridge between strongly-typed Crystal fields and `Value`.
  module Codec
    # Normalizes an annotation key into a canonical `Value` map key.
    def self.normalize_key(key : Int | Value) : Value
      key.is_a?(Int) ? (key <= Int64::MAX ? key.to_i64 : key.to_u64) : key
    end

    # Recursively converts a strongly-typed Crystal field value into `Value`.
    def self.to_cbor_value(value : T) : Value forall T
      case value
      when Value                 then value
      when Int8, Int16, Int32    then value.to_i64
      when UInt8, UInt16, UInt32 then value.to_u64
      when Float32               then value.to_f64
      when Serializable          then value.to_cbor_value
      when Array                 then value.map { |item| to_cbor_value(item).as(Value) }
      when Hash
        result = Hash(Value, Value).new(initial_capacity: value.size)
        value.each { |key, val| result[to_cbor_value(key)] = to_cbor_value(val) }
        result
      end
    end

    # Inserts a field into *map*, omitting `nil` values unless *emit_null* is `true`.
    def self.put_field(map : Hash(Value, Value), key : Int | Value, val : T, emit_null : Bool) : Nil forall T
      return map[normalize_key(key)] = to_cbor_value(val) unless val.nil?
      map[normalize_key(key)] = nil if emit_null
    end

    # Appends a field directly to *entries* on *encoder* without allocating a `Hash(Value, Value)`.
    def self.append_field(
      encoder : Encoder, entries : Array(Encoder::MapEntry), key : Int | Value, val : T, emit_null : Bool,
    ) : Nil forall T
      unless val.nil?
        entry_val = val.is_a?(Serializable) ? val : to_cbor_value(val)
        return encoder.append_entry(entries, normalize_key(key), entry_val)
      end
      encoder.append_entry(entries, normalize_key(key), nil) if emit_null
    end

    # Resolves a field from *map*, returning *default* when *raw_key* is absent.
    def self.field(type : T.class, map : Hash(Value, Value), raw_key : Int | Value, default : T) : T forall T
      key = normalize_key(raw_key)
      map.has_key?(key) ? from_cbor_value(T, map[key]) : default
    end

    # Resolves a required or nilable field from *map*, raising `CborError` when missing.
    def self.field(type : T.class, map : Hash(Value, Value), raw_key : Int | Value) : T forall T
      key = normalize_key(raw_key)
      return from_cbor_value(T, map[key]) if map.has_key?(key)
      {% if T.nilable? %}nil{% else %}raise CborError.new("Missing required CBOR field: #{key.inspect}"){% end %}
    end

    {% for type, conv in {Int8 => :to_i8, Int16 => :to_i16, Int32 => :to_i32} %}
      # Extracts a `{{ type }}` value with bounds checking or raises `CborError`.
      def self.from_cbor_value(type : {{ type }}.class, value : Value) : {{ type }}
        int = value.as?(Int64) || raise CborError.new("Expected {{ type }}, got #{value.class}")
        raise CborError.new("{{ type }} overflow: #{int}") if int < {{ type }}::MIN || int > {{ type }}::MAX
        int.{{ conv.id }}
      end
    {% end %}

    {% for type, conv in {UInt8 => :to_u8, UInt16 => :to_u16, UInt32 => :to_u32, UInt64 => :to_u64} %}
      # Extracts a `{{ type }}` value with bounds checking or raises `CborError`.
      def self.from_cbor_value(type : {{ type }}.class, value : Value) : {{ type }}
        extract_unsigned({{ type }}, value).{{ conv.id }}
      end
    {% end %}

    # Extracts a `Float32` value with finite bounds checking or raises `CborError`.
    def self.from_cbor_value(type : Float32.class, value : Value) : Float32
      raise CborError.new("Expected Float32, got #{value.class}") unless value.is_a?(Float64)
      return value.to_f32 if value.nan? || value.infinite?
      raise CborError.new("Float32 overflow: #{value}") if value < -Float32::MAX.to_f64 || value > Float32::MAX.to_f64
      value.to_f32
    end

    # Extracts a typed `Array(T)` from an `Array(Value)`.
    def self.from_cbor_value(type : Array(T).class, value : Value) : Array(T) forall T
      arr = value.as?(Array(Value)) || raise CborError.new("Expected Array, got #{value.class}")
      arr.map { |item| from_cbor_value(T, item).as(T) }
    end

    # Extracts a typed `Hash(K, V)` from a `Hash(Value, Value)`.
    def self.from_cbor_value(type : Hash(K, V).class, value : Value) : Hash(K, V) forall K, V
      map = value.as?(Hash(Value, Value)) || raise CborError.new("Expected Map, got #{value.class}")
      result = Hash(K, V).new(initial_capacity: map.size)
      map.each { |key, val| result[from_cbor_value(K, key)] = from_cbor_value(V, val) }
      result
    end

    # Extracts scalar `Value` primitives, nilable unions (`T?`), or nested `Serializable` types.
    def self.from_cbor_value(type : T.class, value : Value) : T forall T
      {% if T == Nil || T == Bool || T == Int64 || T == Float64 || T == String || T == Bytes %}
        return value if value.is_a?(T)
        raise CborError.new("Expected #{T}, got #{value.class}")
      {% elsif T.nilable? %}
        value.nil? ? nil : from_cbor_value({{ T.union_types.reject(&.==(Nil)).first }}, value)
      {% elsif T < Crystal::Cbor::Fido::Serializable %}
        map = value.as?(Hash(Value, Value)) || raise CborError.new("Expected CBOR map for #{T}, got #{value.class}")
        T.from_cbor_map(map)
      {% else %}
        raise CborError.new("Unsupported CBOR target type #{T}")
      {% end %}
    end

    private def self.extract_unsigned(type : T.class, value : Value) : UInt64 forall T
      if value.is_a?(Int64)
        raise CborError.new("Expected non-negative #{T}, got #{value}") if value < 0
        u64 = value.to_u64
      else
        u64 = value.as?(UInt64) || raise CborError.new("Expected #{T}, got #{value.class}")
      end
      raise CborError.new("#{T} overflow: #{u64}") if u64 > T::MAX.to_u64
      u64
    end
  end

  # Compile-time mixin synthesizing canonical CBOR serialization and deserialization for structs and classes.
  module Serializable
    # Configures type-level deserialization behavior such as `strict: Bool = true`.
    annotation Options
    end

    macro included
      # Deserializes an instance from a validated canonical CBOR map.
      def self.from_cbor_map(cbor_map : Hash(::CBOR::Value, ::CBOR::Value)) : self
        new(__cbor_map: cbor_map)
      end

      # Decodes a canonical CBOR `Bytes` slice or bounded `IO` stream into `self`.
      def self.from_cbor(
        source : Bytes | IO,
        max_depth : Int32 = ::CBOR::Decoder::MAX_DEPTH,
        max_bytes : UInt64 = ::CBOR::Decoder::DEFAULT_STREAM_MAX_BYTES,
        eof_check : Bool = true,
      ) : self
        io = source.is_a?(Bytes) ? IO::Memory.new(source) : source
        limit = source.is_a?(Bytes) ? ::CBOR::Decoder::MAX_LEN : max_bytes
        val = ::CBOR.decode(io, max_depth: max_depth, max_bytes: limit, eof_check: eof_check)
        map = val.as?(Hash(::CBOR::Value, ::CBOR::Value))
        raise ::CBOR::CborError.new("Expected CBOR map for #{self}") unless map
        from_cbor_map(map)
      end

      {% verbatim do %}
        # Initializes an instance from a decoded `Hash(Value, Value)` map.
        def initialize(*, __cbor_map cbor_map : Hash(::CBOR::Value, ::CBOR::Value)) : Nil
          {% for ivar in @type.instance_vars %}
            {% ann = ivar.annotation(::CBOR::Field) %}
            {% raw_k = (ann && ann[:key] != nil) ? ann[:key] : ivar.name.stringify %}
            {% if ann && ann[:ignore] %}
              {% if ivar.has_default_value? %}@{{ ivar.name }} = {{ ivar.default_value }}{% end %}
            {% elsif ivar.has_default_value? %}
              @{{ ivar.name }} = ::CBOR::Codec.field({{ ivar.type }}, cbor_map, {{ raw_k }}, {{ ivar.default_value }})
            {% else %}
              @{{ ivar.name }} = ::CBOR::Codec.field({{ ivar.type }}, cbor_map, {{ raw_k }})
            {% end %}
          {% end %}
          _verify_cbor_strict_keys(cbor_map)
        end
      {% end %}
    end

    # Converts all non-ignored instance variables into a `Hash(Value, Value)` representation.
    def to_cbor_value : ::CBOR::Value
      map = Hash(::CBOR::Value, ::CBOR::Value).new
      _each_cbor_field { |key, val, emit_null| ::CBOR::Codec.put_field(map, key, val, emit_null) }
      map
    end

    # Serializes `self` as a canonical CBOR map into *encoder* without allocating a `Hash(Value, Value)`.
    def to_cbor(encoder : ::CBOR::Encoder) : Nil
      encoder.encode_map_entries do |entries|
        _each_cbor_field { |key, val, emit_null| ::CBOR::Codec.append_field(encoder, entries, key, val, emit_null) }
      end
    end

    # Serializes `self` in canonical CBOR format directly to *io*.
    def to_cbor(io : IO, max_depth : Int32 = ::CBOR::Encoder::MAX_DEPTH) : Nil
      to_cbor(::CBOR::Encoder.new(io, 0, max_depth))
    end

    # Serializes `self` into a canonical CBOR `Bytes` slice.
    def to_cbor : Bytes
      io = IO::Memory.new
      to_cbor(io)
      io.to_slice
    end

    private def _verify_cbor_strict_keys(cbor_map : Hash(::CBOR::Value, ::CBOR::Value)) : Nil
      {% unless (opts = @type.annotation(::CBOR::Serializable::Options)) && opts[:strict] != nil && !opts[:strict] %}
        cbor_map.each_key do |map_key|
          known = false
          _each_cbor_field { |key, _, _| known = true if map_key == ::CBOR::Codec.normalize_key(key) }
          raise ::CBOR::CborError.new("Unknown CBOR field: #{map_key.inspect}") unless known
        end
      {% end %}
    end

    private def _each_cbor_field(&) : Nil
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::CBOR::Field) %}
        {% unless ann && ann[:ignore] %}
          {% raw_k = (ann && ann[:key] != nil) ? ann[:key] : ivar.name.stringify %}
          yield({{ raw_k }}, @{{ ivar.name }}, {{ (ann && ann[:emit_null]) ? true : false }})
        {% end %}
      {% end %}
    end
  end
end

# Top-level convenience namespace alias for `Crystal::Cbor::Fido`.
alias CBOR = Crystal::Cbor::Fido
