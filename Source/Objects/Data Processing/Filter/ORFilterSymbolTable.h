#define kMaxHashKeyLen 100
#define kMaxNumHashKeys 10007

#define kFilterLongType 0
#define kFilterPtrType  1

typedef struct  {
	long type;
	union {
		unsigned long lValue;
		unsigned long* pValue;
	}val;
}filterData;

struct htab {
	struct htab* child;
	struct htab* parent;
	char key[kMaxHashKeyLen];
	filterData data;
};

typedef struct htab  hashTable;

@interface ORFilterSymbolTable : NSObject
{
	hashTable* hashTab[kMaxNumHashKeys];
}

- (unsigned int) hash:(const char *)aKey;
- (BOOL) setData:(filterData)data forKey:(const char*) key;
- (BOOL) getData:(filterData*)data forKey:(const char*)key;
- (BOOL) removeKey:(const char *)aKey;
- (hashTable*) findHash:(const char*)aKey;

@end