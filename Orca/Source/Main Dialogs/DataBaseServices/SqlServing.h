#import <Foundation/Foundation.h>

// Messages the client will receive from the server
@protocol SqlUsing
- (bycopy NSString*) name;
- (BOOL) stillThere;
@end

// Messages the server will receive from the client
@protocol SqlServing

- (BOOL) registerClient:(in byref id <SqlUsing>)newClient;
- (void) unregisterClient:(in byref id <SqlUsing>)aClient;

- (BOOL) connect:(in bycopy NSString*) clientName
			  to:(in bycopy NSString*) db 
			user:(in bycopy NSString*) uid 
		password:(in bycopy NSString*) pw;
		
- (void) disconnect:(in bycopy NSString*) clientName;
- (void) client:(in bycopy NSString*) clientName execute:(in bycopy NSString*) command;

//   void        Close(Option_t *opt="");
//   TSQLResult *Query(const char *sql);
//   Int_t       SelectDataBase(const char *dbname);
//   TSQLResult *GetDataBases(const char *wild = 0);
//   TSQLResult *GetTables(const char *dbname, const char *wild = 0);
//   TSQLResult *GetColumns(const char *dbname, const char *table, const char *wild = 0);
//   Int_t       CreateDataBase(const char *dbname);
//   Int_t       DropDataBase(const char *dbname);
//   Int_t       Reload();
//   Int_t       Shutdown();
//   const char *ServerInfo();

//   ClassDef(TMySQLServer,0)  // Connection to MySQL server

@end
