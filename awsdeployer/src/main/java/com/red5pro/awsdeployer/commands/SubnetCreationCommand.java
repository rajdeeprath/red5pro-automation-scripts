package com.red5pro.awsdeployer.commands;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import org.apache.commons.chain.Command;
import org.apache.commons.chain.Context;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder;
import com.amazonaws.services.ec2.model.AvailabilityZone;
import com.amazonaws.services.ec2.model.CreateSubnetRequest;
import com.amazonaws.services.ec2.model.CreateSubnetResult;
import com.amazonaws.services.ec2.model.CreateTagsRequest;
import com.amazonaws.services.ec2.model.CreateVpcRequest;
import com.amazonaws.services.ec2.model.CreateVpcResult;
import com.amazonaws.services.ec2.model.DeleteVpcRequest;
import com.amazonaws.services.ec2.model.DeleteVpcResult;
import com.amazonaws.services.ec2.model.DescribeAvailabilityZonesResult;
import com.amazonaws.services.ec2.model.DescribeSubnetsRequest;
import com.amazonaws.services.ec2.model.DescribeSubnetsResult;
import com.amazonaws.services.ec2.model.DescribeVpcsRequest;
import com.amazonaws.services.ec2.model.DescribeVpcsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Subnet;
import com.amazonaws.services.ec2.model.Tag;
import com.amazonaws.services.ec2.model.Vpc;
import com.red5pro.awsdeployer.model.Configuration;

public class SubnetCreationCommand implements Command {
	
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private String[] targetRegions;
	
	
	
	public SubnetCreationCommand()
	{
		
	}
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Starting subnet creation");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		this. targetRegions = configuration.getStreamManagerRegions();
		
		/* For each  target regions */
		
		for(int i=0;i<this.targetRegions.length;i++)
		{
			String region = this.targetRegions[i];
			AmazonEC2 ec2Client = getEc2Client2(region);
			DescribeAvailabilityZonesResult zones_response =    ec2Client.describeAvailabilityZones();
			
			int zoneCounter = 0;

			for(AvailabilityZone zone : zones_response.getAvailabilityZones())
			{
			    System.out.printf("Found availability zone %s " +  "with status %s " +   "in region %s",   zone.getZoneName(),  zone.getState(),   zone.getRegionName());
			    
			    String subnetName = configuration.getVpcName()  +  "- " + zone.getZoneName();
			    String cidr = "10.0." + zoneCounter + ".0/24";
			    
			    System.out.println("Checking for existing subnet");			    
			    
			    DescribeSubnetsRequest readSubnetRequest = new DescribeSubnetsRequest();
			    Filter f1 = new Filter().withName("Name").withValues(subnetName);
			    Filter f2 = new Filter().withName("sessionid").withValues(configuration.getSessionId());
			    readSubnetRequest.withFilters(f1,f2);			    
			    
			    DescribeSubnetsResult result =  ec2Client.describeSubnets(readSubnetRequest);
			    List<Subnet> subnets = result.getSubnets();
			    
			    if(subnets.size() > 0)
			    {
			    	// subnet exists lets use that
			    	Subnet subnet = subnets.get(0);
			    	System.out.println("Subnet already exists by id "  + subnet.getSubnetId()  +  " at " + zone.getZoneName());
			    }
			    else
			    {
			    	// subnet does not exist lets create
			    	CreateSubnetRequest createSubnetRequest = new CreateSubnetRequest();
			    	createSubnetRequest.withAvailabilityZone(zone.getZoneName());

			    	CreateSubnetResult createSubnetResult = ec2Client.createSubnet(createSubnetRequest);
			    	String subnetId = createSubnetResult.getSubnet().getSubnetId();
			    	
			    	List<Tag> tags = new ArrayList<Tag>();
			    	
			    	Tag nameTag = new Tag();
		            nameTag.setKey("Name");
		            nameTag.setValue(configuration.getVpcName());
		            
		            tags.add(nameTag);
		            
		            Tag sessionIdTag = new Tag();
		            sessionIdTag.setKey("sessionid");
		            sessionIdTag.setValue(configuration.getSessionId());
		            
		            tags.add(sessionIdTag);
		            
		            System.out.println("Tagging Subnet " + subnetId);
		            
		            CreateTagsRequest createTagsRequest = new CreateTagsRequest();
		            createTagsRequest.setTags(tags);
		            createTagsRequest.withResources(subnetId) ;
		            ec2Client.createTags(createTagsRequest);
			    }
			    
			    zoneCounter++;
			    
			}
		}
		
		return false;
	}
	
	
	
	
	AmazonEC2 getEc2Client2(String region){
		AmazonEC2 ec2 = AmazonEC2ClientBuilder.standard()
                .withRegion(region)
                .withCredentials(new AWSStaticCredentialsProvider(credentials))
                .build();
		
		return ec2;
	}


}
