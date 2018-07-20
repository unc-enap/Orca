#define kMaxHashKeyLen 100
#define kMaxNumHashKeys 10007

struct htab {
	struct htab* child;
	struct htab* parent;
	char key[kMaxHashKeyLen];
	int32_t data;
};

typedef struct htab hashTable;

@interface ORHashTable : NSObject
{
	hashTable* hashTab[kMaxNumHashKeys];
}

- (unsigned int) hash:(const char *)aKey;
- (BOOL) setData:(int32_t)data forKey:(const char*) key;
- (BOOL) getData:(int32_t*)data forKey:(const char*)key;
- (BOOL) removeKey:(const char *)aKey;
- (hashTable*) findHash:(const char*)aKey;

@end