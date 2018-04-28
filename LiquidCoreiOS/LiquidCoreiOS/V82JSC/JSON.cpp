//
//  JSON.cpp
//  LiquidCoreiOS
//
//  Created by Eric Lange on 2/9/18.
//  Copyright © 2018 LiquidPlayer. All rights reserved.
//

#include "V82JSC.h"

using namespace v8;

/**
 * Tries to parse the string |json_string| and returns it as value if
 * successful.
 *
 * \param json_string The string to parse.
 * \return The corresponding value if successfully parsed.
 */
MaybeLocal<Value> JSON::Parse(Local<Context> context, Local<String> json_string)
{
    assert(0);
    return MaybeLocal<Value>();
}

/**
 * Tries to stringify the JSON-serializable object |json_object| and returns
 * it as string if successful.
 *
 * \param json_object The JSON-serializable object to stringify.
 * \return The corresponding string if successfully stringified.
 */
MaybeLocal<String> JSON::Stringify(Local<Context> context, Local<Object> json_object,
                                   Local<String> gap)
{
    assert(0);
    return MaybeLocal<String>();
}

