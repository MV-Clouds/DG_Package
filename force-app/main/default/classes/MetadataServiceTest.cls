@IsTest
public class MetadataServiceTest {

    @isTest
    static void allWrapperClassTest() {
        MetadataService.LogInfo logInfo = new MetadataService.LogInfo();
        MetadataService.describeMetadataResponse_element describeMdataResponse = new MetadataService.describeMetadataResponse_element();
        MetadataService.describeValueTypeResponse_element describeValueResponse = new MetadataService.describeValueTypeResponse_element();
        MetadataService.updateMetadataResponse_element updateMdataResponse = new MetadataService.updateMetadataResponse_element();
        MetadataService.describeMetadata_element describeMdata = new MetadataService.describeMetadata_element();
        MetadataService.PackageTypeMembers packageTypeMembers = new MetadataService.PackageTypeMembers();
        MetadataService.describeValueType_element describeValueType = new MetadataService.describeValueType_element();
        MetadataService.createMetadata_element createMdata = new MetadataService.createMetadata_element();
        MetadataService.createMetadataResponse_element createMdataResponse = new MetadataService.createMetadataResponse_element();
        MetadataService.readMetadata_element readMdata = new MetadataService.readMetadata_element();
        MetadataService.upsertMetadata_element upsertMdata = new MetadataService.upsertMetadata_element();
        MetadataService.upsertMetadataResponse_element upsertMdataResponse = new MetadataService.upsertMetadataResponse_element();
        MetadataService.listMetadataResponse_element listMdataResponse = new MetadataService.listMetadataResponse_element();
        MetadataService.retrieveResponse_element retrieveResponse = new MetadataService.retrieveResponse_element();
        MetadataService.retrieve_element retrieveEl = new MetadataService.retrieve_element();
        MetadataService.updateMetadata_element updateMdata = new MetadataService.updateMetadata_element();
        MetadataService.PicklistEntry picklistEntry = new MetadataService.PicklistEntry();
        MetadataService.FileProperties fileProperties = new MetadataService.FileProperties();
        MetadataService.RetrieveMessage retrieveMessage = new MetadataService.RetrieveMessage();
        MetadataService.RetrieveResult retrieveResult = new MetadataService.RetrieveResult();
        MetadataService.CancelDeployResult cancelDeployResult = new MetadataService.CancelDeployResult();
        MetadataService.AsyncResult asyncResult = new MetadataService.AsyncResult();
        MetadataService.deployResponse_element deployResponse = new MetadataService.deployResponse_element();
        MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
        MetadataService.DescribeMetadataResult descrobeMdataResult = new MetadataService.DescribeMetadataResult();
        MetadataService.DescribeMetadataObject describeMdataObject = new MetadataService.DescribeMetadataObject();
        MetadataService.deleteMetadata_element deleteMdata = new MetadataService.deleteMetadata_element();
        MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
        MetadataService.Error error = new MetadataService.Error();
        MetadataService.ExtendedErrorDetails extendedErrorDetails = new MetadataService.ExtendedErrorDetails();
        MetadataService.AllOrNoneHeader_element allOrNoneHeader = new MetadataService.AllOrNoneHeader_element();
        MetadataService.CallOptions_element callOptions = new MetadataService.CallOptions_element();
        MetadataService.DebuggingInfo_element debuggingInfo = new MetadataService.DebuggingInfo_element();
        MetadataService.DebuggingHeader_element debuggingHeader = new MetadataService.DebuggingHeader_element();
        MetadataService.Metadata metadata = new MetadataService.Metadata();
        MetadataService.deleteMetadataResponse_element deleteMdataResponse = new MetadataService.deleteMetadataResponse_element();
        MetadataService.ProfileObjectPermissions profileObjectPermissions = new MetadataService.ProfileObjectPermissions();
        MetadataService.ListMetadataQuery listMetadataQuery = new MetadataService.ListMetadataQuery();
        MetadataService.Package_x packageX = new MetadataService.Package_x();
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        MetadataService.DeployMessage deployMessage = new MetadataService.DeployMessage();
        MetadataService.renameMetadata_element renameMetadata = new MetadataService.renameMetadata_element();
        MetadataService.DescribeValueTypeResult describeValueTypeResult = new MetadataService.DescribeValueTypeResult();
        MetadataService.UpsertResult upsertResult = new MetadataService.UpsertResult();
        MetadataService.renameMetadataResponse_element renameMdataResponse = new MetadataService.renameMetadataResponse_element();
        MetadataService.listMetadata_element listMdata = new MetadataService.listMetadata_element();
        MetadataService.ValueTypeField valueTypeField = new MetadataService.ValueTypeField();
        MetadataService.WebLink weblink = new MetadataService.WebLink();

        weblink.description = 'assert description';
        System.assertEquals('assert description', weblink.description, 'The description does not match');
    }

    @IsTest
    static void testDeleteMetadata() {
        MetadataService.deleteMetadataResponse_element mockResponse = new MetadataService.deleteMetadataResponse_element();
        MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
        deleteResult.success = true;
        mockResponse.result = new MetadataService.DeleteResult[] { deleteResult };
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        MetadataService.DeleteResult[] result = metadataPort.deleteMetadata('CustomObject', new String[] {'TestObject'});
        
        System.assertEquals(1, result.size(), 'The size of the result must be 1');
        System.assert(result[0].success, 'The delete operation should be successful.');
    }

    @IsTest
    static void testRenameMetadata() {
        MetadataService.renameMetadataResponse_element mockResponse = new MetadataService.renameMetadataResponse_element();
        MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
        saveResult.success = true;
        mockResponse.result = saveResult;
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.SaveResult result = metadataPort.renameMetadata('CustomObject', 'OldName', 'NewName');
        
        System.assert(result.success, 'The rename operation should be successful.');
    }

    @IsTest
    static void testUpdateMetadata() {
        MetadataService.updateMetadataResponse_element mockResponse = new MetadataService.updateMetadataResponse_element();
        MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
        saveResult.success = true;
        mockResponse.result = new MetadataService.SaveResult[] { saveResult };
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.Metadata mockMetadata = new MetadataService.Metadata();
        mockMetadata.fullName = 'TestMetadata';
        
        MetadataService.SaveResult[] result = metadataPort.updateMetadata(new MetadataService.Metadata[] { mockMetadata });
        
        System.assertEquals(1, result.size(), 'The size of the result must be 1');
        System.assert(result[0].success, 'The update operation should be successful.');
    }
    
    @IsTest
    static void testDescribeMetadata() {
        MetadataService.describeMetadataResponse_element mockResponse = new MetadataService.describeMetadataResponse_element();
        MetadataService.DescribeMetadataResult describeMetadataResult = new MetadataService.DescribeMetadataResult();
        describeMetadataResult.metadataObjects = new MetadataService.DescribeMetadataObject[] {};
        mockResponse.result = describeMetadataResult;
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.DescribeMetadataResult result = metadataPort.describeMetadata(Double.valueOf(42.0));
        
        System.assertNotEquals(null, result, 'The result cannot be null');
        System.assertEquals(0, result.metadataObjects.size(), 'There should be no metadata objects.');
    }

    @IsTest
    static void testRetrieve() {
        MetadataService.retrieveResponse_element mockResponse = new MetadataService.retrieveResponse_element();
        MetadataService.AsyncResult asyncResult = new MetadataService.AsyncResult();
        asyncResult.id = '12345';
        asyncResult.done = true;
        mockResponse.result = asyncResult;
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion = 42.0;
        
        MetadataService.AsyncResult result = metadataPort.retrieve(retrieveRequest);
        
        System.assertEquals('12345', result.id, 'The Id is not equal to 12345');
        System.assert(result.done, 'The retrieve operation should be marked as done.');
    }

    @IsTest
    static void testDescribeValueType() {
        MetadataService.describeValueTypeResponse_element mockResponse = new MetadataService.describeValueTypeResponse_element();
        MetadataService.DescribeValueTypeResult describeValueTypeResult = new MetadataService.DescribeValueTypeResult();
        mockResponse.result = describeValueTypeResult;
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.DescribeValueTypeResult result = metadataPort.describeValueType('CustomObject');
        
        System.assertNotEquals(null, result, 'The result cannot be null');
    }

    @IsTest
    static void testCreateMetadata() {
        MetadataService.createMetadataResponse_element mockResponse = new MetadataService.createMetadataResponse_element();
        MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
        saveResult.success = true;
        mockResponse.result = new MetadataService.SaveResult[] { saveResult };
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.Metadata mockMetadata = new MetadataService.Metadata();
        mockMetadata.fullName = 'TestMetadata';
        
        MetadataService.SaveResult[] result = metadataPort.createMetadata(new MetadataService.Metadata[] { mockMetadata });
        
        System.assertEquals(1, result.size(), 'The size of the result must be 1');
        System.assert(result[0].success, 'The create operation should be successful.');
    }
    
    // @IsTest
    // static void testReadMetadata() {
    //     MetadataService.readMetadata_element mockResponse = new MetadataService.readMetadata_element();
        
    //     Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
    //     MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
    //     MetadataService.IReadResult result = metadataPort.readMetadata('CustomObject', new String[] { 'TestObject' });
    //     System.assertNotEquals(null, result, 'The result cannot be null');
    // }

    @IsTest
    static void testUpsertMetadata() {
        MetadataService.upsertMetadataResponse_element mockResponse = new MetadataService.upsertMetadataResponse_element();
        MetadataService.UpsertResult upsertResult = new MetadataService.UpsertResult();
        upsertResult.success = true;
        mockResponse.result = new MetadataService.UpsertResult[] { upsertResult };
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.Metadata mockMetadata = new MetadataService.Metadata();
        mockMetadata.fullName = 'TestMetadata';
        
        MetadataService.UpsertResult[] result = metadataPort.upsertMetadata(new MetadataService.Metadata[] { mockMetadata });
        
        System.assertEquals(1, result.size(), 'The size of the result must be 1');
        System.assert(result[0].success, 'The upsert operation should be successful.');
    }

    @IsTest
    static void testListMetadata() {
        MetadataService.listMetadataResponse_element mockResponse = new MetadataService.listMetadataResponse_element();
        MetadataService.FileProperties fileProperties = new MetadataService.FileProperties();
        fileProperties.fullName = 'TestObject';
        mockResponse.result = new MetadataService.FileProperties[] { fileProperties };
        
        Test.setMock(WebServiceMock.class, new MetadataServiceMock(mockResponse));
        
        MetadataService.MetadataPort metadataPort = new MetadataService.MetadataPort();
        
        MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
        query.type_x = 'CustomObject';
        
        MetadataService.FileProperties[] result = metadataPort.listMetadata(new MetadataService.ListMetadataQuery[] { query }, Double.valueOf(42.0));
        
        System.assertEquals(1, result.size(), 'The size of the result must be 1');
        System.assertEquals('TestObject', result[0].fullName, 'The fullname od the result is not TestObject');
    }
    
    private class MetadataServiceMock implements WebServiceMock {
        private Object mockResponse;
        
        MetadataServiceMock(Object response) {
            this.mockResponse = response;
        }
        
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseName, String namespace, String methodName) {
            response.put('response_x', mockResponse);
        }
    }
}