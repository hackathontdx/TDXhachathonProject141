global class SDRAgentClass {
    
    @InvocableMethod(Label='CreateQuoteOnUserRequest' description='Creates an Opportunity and Quote based on user request')
    global static List<QuoteResponse> processRequests(List<Request> requests) {
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
            PriceBook2Id = '01udL000003kVgaQAE',
            Status = 'Draft'
        );
        insert quote;
        
        for(ProductCategoryProduct prod:products ){
            QuoteLineItem quoteLine = new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.ProductId,
                Quantity = 1,
                PriceBookEntryId = '01udL000003kVgaQAE',
                UnitPrice = 100
            );
            insert quoteLine;
         }


        QuoteResponse response = new QuoteResponse();
        response.newQuote = quote;

        List<QuoteResponse> responseList = new List<QuoteResponse>();
        responseList.add(response);

        return responseList; 
       
    }

    global class Request {
        @InvocableVariable
        public String catalog;
        @InvocableVariable
        public String category;
        @InvocableVariable
        public String childcategory;
        //@InvocableVariable
        //public String product;
        @InvocableVariable
        public Date startDate;
        @InvocableVariable
        public Date endDate;
        @InvocableVariable
        public String accNumber;
    }

    global class QuoteResponse{
        @InvocableVariable(description='New Quote created for the user') 
        public Quote newQuote;
    }
}