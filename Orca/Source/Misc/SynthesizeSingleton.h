//----Taken from the web ... 11/21/08 MAH
#define SYNTHESIZE_SINGLETON_FOR_ORCLASS(classname) \
\
static OR##classname* shared##classname = nil; \
\
+ (OR##classname*) shared##classname \
{ \
@synchronized(self) { \
if (shared##classname == nil) { \
[[self alloc] init]; \
} \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) { \
if (shared##classname == nil) { \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \
\
- (id)retain \
{ \
return self; \
} \
\
- (NSUInteger)retainCount \
{ \
return 0xffffffff; \
} \
\
- (oneway void)release \
{ \
} \
\
- (id)autorelease \
{ \
return self; \
}

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
\
static classname* shared##classname = nil; \
\
+ (classname*) shared##classname \
{ \
@synchronized(self) { \
if (shared##classname == nil) { \
[[self alloc] init]; \
} \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) { \
if (shared##classname == nil) { \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \
\
- (id)retain \
{ \
return self; \
} \
\
- (NSUInteger)retainCount\
{ \
return 0xffffffff; \
} \
\
- (oneway void)release \
{ \
} \
\
- (id)autorelease \
{ \
return self; \
}
