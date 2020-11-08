
#include "json.h"
#include "stdint.h"

namespace eihort {
namespace json {

namespace {

// JSON characters
enum {
	// Whitespace
	JC_SP = 0x20u, // ' '
	JC_HT = 0x09u, // '\t'
	JC_LF = 0x0au, // '\n'
	JC_CR = 0x0du, // '\r'

	// Structural
	JC_LBRACKET = 0x5bu, // '['
	JC_RBRACKET = 0x5du, // ']'
	JC_LBRACE = 0x7bu, // '{'
	JC_RBRACE = 0x7du, // '}'
	JC_COLON = 0x3au, // ':'
	JC_COMMA = 0x2cu, // ','

	// String specials
	JC_QUOTE = 0x22u, // '"'
	JC_ESC = 0x5cu, // '\\'

};

class BufferIterator {
public:
	inline BufferIterator( const void *data, std::size_t size )
		: _data( reinterpret_cast<const uint8_t *>(data) )
		, _tail( &_data[size] )
	{}

	inline ~BufferIterator()
	{}

	inline bool eof() const
	{ return !( _data < _tail ); }

	inline BufferIterator& operator++()
	{
		if( !eof() )
			++_data;
		return *this;
	}

	inline uint8_t operator*() const
	{
		if( !eof() )
			return *_data;
		else
			return '\0';
	}

private:
	// Kill copy & assignment
	BufferIterator( const BufferIterator& ) = delete;
	BufferIterator& operator=( const BufferIterator& ) = delete;

	const uint8_t *_data, *_tail;

}; // BufferIterator

static
uint8_t
skipWhite( BufferIterator& it )
{
	// Skip any characters that are JSON whitespace
	for( ;; )
		switch( *it )
		{
			case JC_SP: case JC_HT: case JC_LF: case JC_CR:
				++it;
				break;
			default:
				return *it;
		}
}

static
bool
parseHex( uint8_t& digit, uint8_t ch )
{
	// For ABNF (and JSON), only [0-9A-F] are allowed (not [a-f])
	 // NOTE: Minecraft also allows [a-f], so do we
	if( 0x30u <= ch && ch <= 0x39u ) // '0' to '9'
		digit = ch - 0x30u;
	else if( 0x41u <= ch && ch <= 0x46u ) // 'A' to 'F'
		digit = ch - 0x41u + 10u;
	else if( 0x61u <= ch && ch <= 0x66u ) // 'a' to 'f'
		digit = ch - 0x61u + 10u;
	else
		return false;

	return true;
}

static
void
encodeUTF8( std::string& value, uint32_t ch )
{
	uint8_t digits[6];
	static const uint8_t mask[6] = { 0x00u, 0xc0u, 0xe0u, 0xf0u, 0xf8u, 0xfcu };

	// Mask out invalid bits
	ch &= 0x7ffffffflu;

	// Split ch to 6-bit parts
	int t = 0;
	for( ; ch > 0; ch >>= 6 )
		digits[t++] = ch & 0x3fu;
	if( t == 0 )
		digits[t++] = 0u;

	// Push leader
	value.push_back( mask[t-1] | digits[t-1] );
	// Push continuation characters
	while( --t > 0 )
		value.push_back( 0x80u | digits[t-1] );
}

static
bool
parseString( std::string& value, BufferIterator& it )
{
	// Parse leading '"'
	if( *it != JC_QUOTE )
		return false;

	// Parse content
	while( *++it != JC_QUOTE )
	{
		// Premature EOF
		if( it.eof() )
			return false;

		// Escaped? 
		if( *it == JC_ESC )
			switch( *++it )
			{
				// Escaped self
				case JC_QUOTE: // '"'
				case JC_ESC:   // '\'
				case 0x2fu:    // '/'
					value.push_back( *it ); break;

				// Escaped, with special meaning
				case 0x62u: // 'b'
					value.push_back( 0x08u ); break;
				case 0x66u: // 'f'
					value.push_back( 0x0cu ); break;
				case 0x6eu: // 'n'
					value.push_back( 0x0au ); break;
				case 0x72u: // 'r'
					value.push_back( 0x0du ); break;
				case 0x74u: // 't'
					value.push_back( 0x09u ); break;

				// Hex digit encoding "\uXXXX"
				case 0x75u: // 'u'
					{{
					uint32_t ch = 0u;
					for( int i = 0; i < 4; ++i )
					{
						uint8_t digit;
						if( !parseHex( digit, *++it ) )
							return false;
						ch = 16u * ch + digit;
					}
					encodeUTF8( value, ch );
					}}
					break;

				// Invalid
				default:
					return false;
			}
		else
			value.push_back( *it );
	}

	// Skip terminating quote
	++it;

	return true;
}

} // (anonymous)

bool
Object::parse( const void *data, std::size_t size )
{
	BufferIterator it(data, size);

	// Parse leading '{'
	if( skipWhite( it ) != JC_LBRACE )
		return false;

	// Non-empty object?
	if( skipWhite( ++it ) != JC_RBRACE )
	{
		// Parse content
		for( bool done = false; !done; )
		{
			// Parse "key" : "value"
			std::string key, value;
			if( !parseString( key, it ) )
				return false;
			if( skipWhite( it ) != JC_COLON )
				return false;
			skipWhite( ++it );
			if( !parseString( value, it ) )
				return false;

			// Check for ',' or '}'
			done = skipWhite( it ) == JC_RBRACE;
			if( !done )
			{
				if( *it != JC_COMMA )
					return false;
				skipWhite( ++it ); // Skip ','
			}
	
			// Add 
			insert( end(), std::make_pair( key, value ) );
		}
	}

	// Skip the '}' and check that we're done
	skipWhite( ++it );
	if( !it.eof() )
		return false;

	return true;
}

} // json
} // eihort
