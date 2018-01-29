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
import com.amazonaws.services.ec2.model.CreateTagsRequest;
import com.amazonaws.services.ec2.model.CreateVpcRequest;
import com.amazonaws.services.ec2.model.CreateVpcResult;
import com.amazonaws.services.ec2.model.DeleteVpcRequest;
import com.amazonaws.services.ec2.model.DeleteVpcResult;
import com.amazonaws.services.ec2.model.DescribeVpcsRequest;
import com.amazonaws.services.ec2.model.DescribeVpcsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.Tag;
import com.amazonaws.services.ec2.model.Vpc;
import com.red5pro.awsdeployer.model.Configuration;

public class VPCCreationCommand implements Command {
	
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private String[] targetRegions;
	
	private List<Vpc> created = new ArrayList<Vpc>();
	
	
	public VPCCreationCommand()
	{
		
	}
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Starting Vpc creation");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		this. targetRegions = configuration.getStreamManagerRegions();
		
		/* For each  target regions */
		
		for(int i=0;i<this.targetRegions.length;i++)
		{
			String region = this.targetRegions[i];
			
			try
			{
				AmazonEC2 ec2Client = getEc2Client2(region);
				
				System.out.print("Creating Vpc for autoscaling...");
				
				Filter name = new Filter().withName("tag:Name").withValues(configuration.getVpcName());
				Filter sessionId = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
				
				DescribeVpcsRequest checkVpcRequest = new DescribeVpcsRequest().withFilters(new Filter[] {name, sessionId});
				DescribeVpcsResult vpcResponse = ec2Client.describeVpcs(checkVpcRequest);
				List<Vpc> vpcs = vpcResponse.getVpcs();
				
				if(vpcs.size()>0)
				{
					System.err.println("Vpc by the name " + configuration.getVpcName() + " already exists. This region will be skipped. You should select the same but unique name for all your Vpcs across regions");
					Thread.sleep(5000);
					
					Scanner in = new Scanner(System.in);
					System.out.print("You you wish to delete this Vpc and re create a new one ? (Y/N) - (WARNING!! All subnets and other network componenst will ne lost as well!!)");
					String a = in.next();
					
					if(a != null && a.toLowerCase().equalsIgnoreCase("y"))
					{
						for(Vpc vpc : vpcs)
						{
							DeleteVpcRequest delRequest = new DeleteVpcRequest().withVpcId(vpc.getVpcId());
							DeleteVpcResult delResult =  ec2Client.deleteVpc(delRequest);
							System.out.println("Deleted Vpc " + vpc.getVpcId() + " in region " + region);
						}
					}
					else
					{
						System.err.print("Please delete all Vpcs by the name " + configuration.getVpcName() + " from all regions and start this program once again.");
						throw new Exception("Unable to create vpc since one already exists by the same name in the region " + region);
					}
				}
				
				CreateVpcRequest newVPC = new CreateVpcRequest().withCidrBlock(configuration.getVpcCidr());
				CreateVpcResult res = ec2Client.createVpc(newVPC);
				
				Vpc vpc = res.getVpc();
				created.add(vpc);
				
				System.out.println("Vpc " +  vpc.getVpcId() + " created @ region " +  region);		
				
				List<Tag> tags = new ArrayList<Tag>();
	            
				Tag nameTag = new Tag();
	            nameTag.setKey("Name");
	            nameTag.setValue(configuration.getVpcName());
	            
	            tags.add(nameTag);
	            
	            Tag sessionIdTag = new Tag();
	            sessionIdTag.setKey("sessionid");
	            sessionIdTag.setValue(configuration.getSessionId());
	            
	            tags.add(sessionIdTag);
	            
	            System.out.println("Tagging VPC " + vpc.getVpcId());
	            
	            CreateTagsRequest createTagsRequest = new CreateTagsRequest();
	            createTagsRequest.setTags(tags);
	            createTagsRequest.withResources(vpc.getVpcId()) ;
	            ec2Client.createTags(createTagsRequest);            
			}
			catch (AmazonServiceException e) 
			{
		        System.err.println("Error in VPC creation...");
		    	System.err.println("Caught Exception: " + e.getMessage());
		        System.err.println("Reponse Status Code: " + e.getStatusCode());
		        System.err.println("Error Code: " + e.getErrorCode());
		        System.err.println("Request ID: " + e.getRequestId());
		        
		        throw new Exception("Failed in creating elastic IP resources");
			}
			
            
            System.out.println("Done...");
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
