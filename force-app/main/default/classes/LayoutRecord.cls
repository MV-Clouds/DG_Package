public class LayoutRecord {

    public List<Record> records {get;set;} 

    public class Layout {
        public String Name {get;set;} 
    }
    public class Record {
        public Layout Layout {get;set;} 
    } 
    
    public static LayoutRecord parse(String json){
        System.debug(json);
        return (LayoutRecord) System.JSON.deserialize(json, LayoutRecord.class);
    }
}