#define kMaxHashKeyLen 100
#define kMaxNumHashKeys 10007

struct htab {
	struct htab* child;
	struct htab* parent;
	char key[kMaxHashKeyLen];
	long data;
};

typedef struct htab hashTable;

@interface ORHashTable : NSObject
{
	hashTable* hashTab[kMaxNumHashKeys];
}

- (unsigned int) hash:(const char *)aKey;
- (BOOL) setData:(long)data forKey:(const char*) key;
- (BOOL) getData:(long*)data forKey:(const char*)key;
- (BOOL) removeKey:(const char *)aKey;
- (hashTable*) findHash:(const char*)aKey;

@end