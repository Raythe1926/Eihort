#ifndef JSON_H_
#define JSON_H_

#include <cstddef>
#include <map>
#include <string>

namespace eihort {
namespace json {

	// Represents a JSON object
	 // at the moment, this only parses string -> string maps
	class Object : public std::map<std::string, std::string> {
	public:
		// Parse some text & populate the object 
		bool parse( const void *data, std::size_t size );

	}; // Object

} // json
} // eihort

#endif // JSON_H_
