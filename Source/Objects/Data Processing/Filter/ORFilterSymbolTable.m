#include <strings.h>
#include <stdio.h>
#include <limits.h>
#include <math.h>
#include "ORFilterSymbolTable.h"

@implementation ORFilterSymbolTable

#undef get16bits
#if (defined(__GNUC__) && defined(__i386__)) || defined(__WATCOMC__) \
  || defined(_MSC_VER) || defined (__BORLANDC__) || defined (__TURBOC__)
#define get16bits(d) (*((const uint16_t *) (d)))
#endif

#if !defined (get16bits)
#define get16bits(d) ((((uint32_t)(((const uint8_t *)(d))[1])) << 8)\
                       +(uint32_t)(((const uint8_t *)(d))[0]) )
#endif

- (unsigned int) hash:(const char *)data
{
uint32_t len = strlen(data);
uint32_t hash = len, tmp;
int rem;

    if (len <= 0 || data == NULL) return 0;

    rem = len & 3;
    len >>= 2;

    /* Main loop */
    for (;len > 0; len--) {
        hash  += get16bits (data);
        tmp    = (get16bits (data+2) << 11) ^ hash;
        hash   = (hash << 16) ^ tmp;
        data  += 2*sizeof (uint16_t);
        hash  += hash >> 11;
    }

    /* Handle end cases */
    switch (rem) {
        case 3: hash += get16bits (data);
                hash ^= hash << 16;
                hash ^= data[sizeof (uint16_t)] << 18;
                hash += hash >> 11;
                break;
        case 2: hash += get16bits (data);
                hash ^= hash << 11;
                hash += hash >> 17;
                break;
        case 1: hash += *data;
                hash ^= hash << 10;
                hash += hash >> 1;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;

    return hash % kMaxNumHashKeys;;
}

/*- (unsigned int) hash:(char *)aKey
{
	int i, n;			// Our temporary variables
	unsigned int hashval;
	unsigned int ival;
	char *p;			// p lets us reference the integer value as a
	// character array instead of an integer.  This
	// is actually pretty bad style even though it
	// works.  You should try a union if you know
	// how to use them.
	
	p = (char *) &ival;		// Make p point to i, without the type cast you					// should get a warning.
	
	hashval = ival = 0;		// Initialize our variables
	
	// Figure out how many characters are in an integer the correct answer is 4 (on an i386), but this should be more cross platform.
	n = (((log10((double)(UINT_MAX)) / log10(2.0))) / CHAR_BIT) + 0.5;
	
	// loop through s four characters at a time
	for(i = 0; i < strlen(aKey); i += n) {
		// voodoo to put the string in an integer don't try and use strcpy, it
		// is a very bad idea and you will corrupt something.
		strncpy(p, aKey + i, n);
		// accumulate our values in hashval
		hashval += ival;
	}
	
	// divide by the number of elements and return our remainder
	return hashval % kMaxNumHashKeys;
}
*/
- (BOOL) setData:(filterData)data forKey:(const char*) key
{
	hashTable *newhash;
	hashTable *curhash;
	unsigned int hashval;
	//might already be in the table, then we'll just replace the value
	curhash = [self findHash:key];
	if(curhash){
		curhash->data = data;
		return YES;
	}
	else {
		newhash = (hashTable *)(malloc(sizeof(hashTable)));
		if (newhash == NULL) return NO;
		
		strcpy(newhash->key, key);
		newhash->data = data;
		
		hashval = [self hash:key];
		
		if (hashTab[hashval] == NULL) {
			hashTab[hashval] = newhash;
			hashTab[hashval]->parent = NULL;
			hashTab[hashval]->child = NULL;
		}
		else {
			curhash=hashTab[hashval];
			while(curhash->child != NULL) {
				curhash=curhash->child;
			}
			curhash->child = newhash;
			newhash->child = NULL;
			newhash->parent = curhash;
		}
		return YES;
	}
	return NO;
}

- (BOOL) getData:(filterData*)data forKey:(const char*)key
{
	hashTable* curhash;
	
	memset(data, 0, sizeof(filterData));
	
	unsigned int hashval = [self hash:key];
	
	
	if (hashTab[hashval] == NULL) return NO;
	
	
	if (!strcmp((hashTab[hashval]->key), (key))) {
		*data =  hashTab[hashval]->data;
		return YES; 
	}
	else {
		if (hashTab[hashval]->child == NULL) return NO;
		
		curhash = hashTab[hashval]->child;
		
		
		if (!strcmp((curhash->key), (key))) {
			*data =  curhash->data;
			return YES; 
		}
		
		while (curhash->child != NULL) {
			if (!strcmp((curhash->key), (key))){
				*data =  curhash->data;
				return YES; 
			}
			curhash = curhash->child;
		}
		if (!strcmp((curhash->key), (key))){
			*data =  curhash->data;
			return YES; 
		}
		else return NO;
	}
	return NO;
}

-(hashTable*) findHash:(const char*) aKey
{
   hashTable *curhash;

   unsigned int hashval = [self hash:aKey];

   if (hashTab[hashval] == NULL) return NULL;
 
   if (!strcmp((hashTab[hashval]->key), aKey)) {
      curhash = hashTab[hashval];
      return curhash; 
   }
   else {
      if (hashTab[hashval]->child == NULL) return NULL;

      curhash = hashTab[hashval]->child;


      if (!strcmp((curhash->key), aKey)) {
         return curhash;
      }

      while (curhash->child != NULL) {
         if (!strcmp((curhash->key), aKey)) return curhash;
         curhash = curhash->child;
      }
      if (!strcmp((curhash->key), aKey)) return curhash;
      else return NULL;
   }
}


- (BOOL) removeKey:(const char*) key
{
	hashTable*   curhash;

	unsigned int hashval = [self hash:key];
	
	
	if (hashTab[hashval] == NULL) {
		return 0;
	}
	
	if (!strcmp((hashTab[hashval]->key), (key))) {
		curhash = hashTab[hashval];
		hashTab[hashval] = curhash->child;
		free(curhash);
		return 1; 
	}
	else {
		if (hashTab[hashval]->child == NULL) {
			return 0;
		}
		
		curhash = hashTab[hashval]->child;
		
		
		if (!strcmp((curhash->key), (key))) {
			curhash->parent->child = curhash->child;
			if (curhash->child != NULL) {
				curhash->child->parent = curhash->parent;
			}
			free(curhash);
			return 1; 
		}
		
		while (curhash->child != NULL) {
			if (!strcmp((curhash->key), (key))) {
				curhash->parent->child = curhash->child;
				if (curhash->child != NULL) {
					curhash->child->parent = curhash->parent;
				}
				free(curhash);
				return 1; 
			}
			curhash = curhash->child;
		}
		if (!strcmp((curhash->key), (key))) {
			curhash->parent->child = curhash->child;
			if (curhash->child != NULL) {
				curhash->child->parent = curhash->parent;
			}
			free(curhash);
			return 1; 
		}
		else {
			return 0;
		}
	}
}

@end
