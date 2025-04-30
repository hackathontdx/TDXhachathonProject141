global class CreateQuoteAndQuoteLines{
    
    @InvocableMethod(Label='CreateOpportunityAndQuoteOnUserRequest' description='Creates an Opportunity and Quote based on user request')
    global static List<QuoteResponse> processRequests(List<Request> requests) {
        Request req = requests[0];
        if(!String.isBlank(req.category) && !String.isBlank(req.childcategory))
            return createQuoteandOpportunity(requests);
        else if(!String.isBlank(req.category))
            return fetchChildCategory(requests);
        else
            return fetchCategory(requests);
       
    }
    
    global static List<QuoteResponse> fetchCategory(List<Request> requests) {
        Request req = requests[0];
        
        List<ProductCatalog> cata = [SELECT Id from ProductCatalog WHERE Name = :req.catalog LIMIT 1];
        List<ProductCategory> Categ = [SELECT Name FROM  ProductCategory WHERE CatalogId = :cata[0].Id AND ParentCategoryId = null ];
        
        String out;
        for(ProductCategory cat: Categ){
            if(out != null)
                out +='• '+cat.Name;
            else
                out ='• '+cat.Name;
        }
        QuoteResponse response = new QuoteResponse();
        
        response.output = 'Please add Category from the List Given Below: /n'+ out;
        List<QuoteResponse> responseList = new List<QuoteResponse>();
        responseList.add(response);

        return responseList; 
    }
    
    public static List<QuoteResponse> fetchChildCategory(List<Request> requests){
        Request req = requests[0];
        List<ProductCategory> Categ = [select Id, Name from ProductCategory where ParentCategory.Name = :req.category and Catalog.Name = :req.catalog];
        
        String out;
        for(ProductCategory cat: Categ){
            if(out != null)
                out +='• '+cat.Name;
            else
                out ='• '+cat.Name;
        }
        
        QuoteResponse response = new QuoteResponse();
        
        response.output = 'Please add child Category from the List Given Below: /n'+ out;
        List<QuoteResponse> responseList = new List<QuoteResponse>();
        responseList.add(response);

        return responseList; 
    }
    
    public static List<QuoteResponse> createQuoteandOpportunity(List<Request> requests){
        Request req = requests[0];
        Account acc = [ SELECT Id from Account WHERE AccountNumber = :req.accNumber ];
        List<ProductCategoryProduct> products = [SELECT ProductId 
                                                 FROM ProductCategoryProduct WHERE 
                                                 ProductCategory.Name = :req.childcategory AND 
                                                 ProductCategory.ParentCategory.Name = :req.category AND 
                                                 ProductCategory.ParentCategory.Catalog.Name = :req.catalog];
        system.debug(products);
        
        Opportunity opp = new Opportunity(
            Name = 'New Opportunity',
            AccountId = acc.Id,
            StageName = 'Propose',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // Create Quote
        Quote quote = new Quote(
            Name = 'New Quote',
            OpportunityId = opp.Id,
            EndDate= req.endDate,
            PriceBook2Id = '01sdL00000ALBFdQAP',
            Status = 'Draft'
        );
        insert quote;
        
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>([select id, name, UnitPrice, Product2Id, Pricebook2Id from PricebookEntry]);
        Map<Id, Id> productPBEMap = new Map<Id, Id>();
        
        for(PriceBookEntry pbe: pbeList){
            productPBEMap.put(pbe.Product2Id, pbe.Id);
        }
                
        for(ProductCategoryProduct prod:products ){
            QuoteLineItem quoteLine = new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.ProductId,
                Quantity = 1,
                PriceBookEntryId = productPBEMap.get(prod.ProductId),
                UnitPrice = 100
            );
            insert quoteLine;
         }


        QuoteResponse response = new QuoteResponse();
        response.newQuote = quote;
        response.output = 'Please review the Quote and sync it to Opportunity';
        List<QuoteResponse> responseList = new List<QuoteResponse>();
        responseList.add(response);

        return responseList; 
    }

    global class Request {
        @InvocableVariable
        public String accNumber;
        @InvocableVariable
        public Date startDate;
        @InvocableVariable
        public Date endDate;
        @InvocableVariable
        public String catalog;
        @InvocableVariable
        public String category;
        @InvocableVariable
        public String childcategory;
    }

    global class QuoteResponse{
        @InvocableVariable(description='New Quote created for the user') 
        public Quote newQuote;
        @InvocableVariable(description='output message') 
        public String output;
    }
}