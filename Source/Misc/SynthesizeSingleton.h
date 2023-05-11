//----Taken from the web ... 11/21/08 MAH
#define SYNTHESIZE_SINGLETON_FOR_ORCLASS(classname) \
\
static OR##classname* shared##classname = nil; \
\
+ (OR##classname*) shared##classname \
{ \
@synchronized(self) { \
    if (shared##classname == nil) { \
        shared##classname = [[super allocWithZone:NULL] init];\
    } \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
    @synchronized(self) { \
        return [[self shared##classname] retain];\
    } \
}

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
\
static classname* shared##classname = nil; \
\
+ (classname*) shared##classname \
{ \
    @synchronized(self) { \
        if (shared##classname == nil) { \
            shared##classname = [[super allocWithZone:NULL] init];\
        } \
        return shared##classname; \
    } \
}\
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
    @synchronized(self) { \
        return [[self shared##classname] retain];\
    } \
    return nil; \
}\
